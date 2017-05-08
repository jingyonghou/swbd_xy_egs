#########################################################################################
# Let's build universal-context bottleneck network
# - Universal context MLP is a hierarchy of two bottleneck neural networks
# - The first network has limited range of frames on input (11 frames)
# - The second network input is a concatenation of bottlneck outputs from the first
#   network, with temporal shifts -10 -5..5 10, (in total a range of 31 frames
#   in the original feature space)
# - This structure produces superior performance w.r.t. single bottleneck network
#
# Train SBN
stage=1
gmmdir=/mnt/jyhou/kaldi/egs/swbd/s5c/exp/tri4
lang=data/lang
train="train_nodup"

batch_size=2048
learn_rate=0.001
momentum=0
scheduler_opts="\"--momentum $momentum\""
train_tool_opts="--minibatch-size=${batch_size} --randomizer-size=32768 --randomizer-seed=777"

if [ $stage -le 1 ]; then
    alidir="exp/{nn_ali_xiaoying_train,tri4_ali_swbd_train_nodup}"
    lables_pdf="ali-pdf.ark"
    ali-to-pdf exp/tri4_ali_swbd_train_nodup/final.mdl "ark:gunzip -c $alidir/ali.*.gz |" ark:$lables_pdf
fi

if [ $stage -le 2 ]; then
  # Train 1st network, overall context +/-5 frames
  # - the topology is 90_1500_1500_80_1500_NSTATES, linear bottleneck,
  dir=exp/${train}-nnet5uc-part1
  labels="\"ark:ali-to-post ark:ali-pdf.ark ark:- |\""
  ali="exp/tri4_ali_swbd_train_nodup"
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --hid-layers 2 --hid-dim 1500 --bn-dim 80 \
      --scheduler-opts $scheduler_opts \
      --copy-feats false --train-tool-opts "$train_tool_opts" \
      --cmvn-opts "--norm-means=true --norm-vars=false" \
      --feat-type traps --splice 5 --traps-dct-basis 6 --learn-rate $learn_rate \
      --labels $labels \
      data-fbank/${train}_tr90 data-fbank/${train}_cv10 $lang $ali $ali $dir
fi

if [ $stage -le 3 ]; then
  # Compose feature_transform for the next stage,
  # - remaining part of the first network is fixed,
  dir=exp/${train}-nnet5uc-part1
  feature_transform=$dir/final.feature_transform.part1
  # Create splice transform,
  nnet-initialize <(echo "<Splice> <InputDim> 80 <OutputDim> 1040 <BuildVector> -10 -5:5 10 </BuildVector>") \
    $dir/splice_for_bottleneck.nnet
  # Concatanate the input-transform, 1stage network, splicing,
  nnet-concat $dir/final.feature_transform "nnet-copy --remove-last-components=4 $dir/final.nnet - |" \
    $dir/splice_for_bottleneck.nnet $feature_transform

  # Train 2nd network, overall context +/-15 frames,
  # - the topology will be 1040_1500_1500_30_1500_NSTATES, linear bottleneck,
  # - cmvn_opts get imported inside 'train.sh',
  dir=exp/${train}-nnet5uc-part2
  labels="\"ark:ali-to-post ark:ali-pdf.ark ark:- |\""
  ali="exp/tri4_ali_swbd_train_nodup"
  $cuda_cmd $dir/log/train_nnet.log \
    steps/nnet/train.sh --hid-layers 2 --hid-dim 1500 --bn-dim 30 \
      --scheduler-opts $scheduler_opts \
      --copy-feats false --train-tool-opts "$train_tool_opts" \
      --feature-transform $feature_transform --learn-rate $learn_rate \
      --labels $labels \
    data-fbank/${train}_tr90 data-fbank/${train}_cv10 $lang $ali $ali $dir 
fi
