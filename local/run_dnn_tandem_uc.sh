#!/bin/bash

# Copyright 2012-2014  Brno University of Technology (Author: Karel Vesely)
# Apache 2.0

# This example script trains a bottleneck feature extractor with 
# 'Universal Context' topology as invented by Frantisek Grezl,
# the network is on top of FBANK+f0 features.

. ./cmd.sh
. ./path.sh

# Config:
stage=3 # resume training with --stage=N
has_fisher=true
export LC_ALL=C;
# End of config.
. utils/parse_options.sh || exit 1;
#

#set -euxo pipefail 

train_src=data/train_nodup
train=mfcc_htk/train_nodup

dev_src=data/eval2000
dev=mfcc_htk/eval2000

gmmdir=exp/tri4

lang=data/lang
lang_test=data/lang_sw1_tg

if [ $stage -le 1 ]; then
  [ -e $dev ] && echo "Existing '$dev', better quit than overwrite!!!" && exit 1
  # prepare the FBANK+f0 features,
  # eval2000,
  utils/copy_data_dir.sh  $dev_src $dev; rm $dev/{feats,cmvn}.scp $dev/{spk2utt,utt2spk}
  # head we reprepare the spk2utt file
  cut -d" " -f1 $dev/segments > $dev/wav.id
  paste $dev/wav.id $dev/wav.id > $dev/spk2utt
  cp $dev/spk2utt $dev/utt2spk
  steps/make_fbank.sh --cmd "$train_cmd" --nj 20 $dev $dev/log $dev/data
  steps/compute_cmvn_stats.sh $dev $dev/log $dev/data

  # training set,
  utils/copy_data_dir.sh $train_src $train; rm $train/{feats,cmvn}.scp train/{spk2utt,utt2spk}
  # head we reprepare the spk2utt file
  cut -d" " -f1 $train/segments > $train/wav.id
  paste $train/wav.id $train/wav.id > $train/spk2utt
  cp $train/spk2utt $train/utt2spk
  steps/make_fbank.sh --cmd "$train_cmd" --nj 20 $train $train/log $train/data
  steps/compute_cmvn_stats.sh $train $train/log $train/data
fi


if [ $stage -le 2 ]; then
  # split the data : 90% train, 10% cross-validation (held-out set),
  utils/subset_data_dir_tr_cv.sh $train ${train}_tr90 ${train}_cv10
fi

#########################################################################################
# Let's build universal-context bottleneck network
# - Universal context MLP is a hierarchy of two bottleneck neural networks
# - The first network has limited range of frames on input (11 frames)
# - The second network input is a concatenation of bottlneck outputs from the first 
#   network, with temporal shifts -10 -5..5 10, (in total a range of 31 frames 
#   in the original feature space)
# - This structure produces superior performance w.r.t. single bottleneck network
#
batch_size=4096
learn_rate=0.00006
momentum=0.9
scheduler_opts="\"--momentum $momentum\""
train_tool_opts="--minibatch-size=${batch_size} --randomizer-size=32768 --randomizer-seed=777"
tag="original_htk_mfcc_no_mvn"
if [ $stage -le 3 ]; then
  # Train 1st network, overall context +/-5 frames
  # - the topology is 90_1500_1500_80_1500_NSTATES, linear bottleneck,
  dir=exp/swbd_${batch_size}_${learn_rate}_${momentum}_${tag}-nnet5uc-part1
  ali=${gmmdir}_ali_nodup
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --hid-layers 2 --hid-dim 1500 --bn-dim 80 \
      --scheduler-opts $scheduler_opts \
      --copy-feats false --train-tool-opts "$train_tool_opts" \
      --cmvn-opts "--norm-means=false --norm-vars=false" \
      --feat-type traps --splice 5 --traps-dct-basis 6 --learn-rate $learn_rate \
      ${train}_tr90 ${train}_cv10 $lang $ali $ali $dir
fi
#
if [ $stage -le 4 ]; then
  # Compose feature_transform for the next stage, 
  # - remaining part of the first network is fixed,
  dir=exp/swbd_${batch_size}_${learn_rate}_${momentum}_${tag}-nnet5uc-part1
  feature_transform=$dir/final.feature_transform.part1
  # Create splice transform,
  nnet-initialize <(echo "<Splice> <InputDim> 80 <OutputDim> 880 <BuildVector>  -5:5 </BuildVector>") $dir/splice_for_bottleneck.nnet 
  # Concatanate the input-transform, 1stage network, splicing,
  nnet-concat $dir/final.feature_transform "nnet-copy --remove-last-components=4 $dir/final.nnet - |" \
    $dir/splice_for_bottleneck.nnet $feature_transform
  
  # Train 2nd network, overall context +/-15 frames,
  # - the topology will be 1040_1500_1500_30_1500_NSTATES, linear bottleneck,
  # - cmvn_opts get imported inside 'train.sh',
  dir=exp/swbd_${batch_size}_${learn_rate}_${momentum}_${tag}-nnet5uc-part2
  ali=${gmmdir}_ali_nodup
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --hid-layers 2 --hid-dim 1500 --bn-dim 30 \
    --scheduler-opts $scheduler_opts \
    --copy-feats false --train-tool-opts "$train_tool_opts" \
    --feature-transform $feature_transform --learn-rate $learn_rate \
    ${train}_tr90 ${train}_cv10 $lang $ali $ali $dir
fi
#
#########################################################################################

# Decode the 2nd DNN,
if [ $stage -le 5 ]; then
  dir=exp/swbd_${batch_size}_${learn_rate}_${momentum}_${tag}-nnet5uc-part2
  steps/nnet/decode.sh --nj 20 --cmd "$decode_cmd" --config conf/decode_dnn.config --acwt 0.08333 \
    $gmmdir/graph_sw1_tg $dev $dir/decode_eval2000_sw1_tg
fi
echo Done.
