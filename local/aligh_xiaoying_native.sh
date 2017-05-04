. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)
stage=1
data_src=data/xiaoying_native
data_mfcc=data-mfcc/xiaoying_native
data_fbank=data-fbank-pitch/xiaoying_native

gmmdir=/mnt/jyhou/kaldi/egs/swbd/s5c/exp/tri4
nndir=/mnt/jyhou/kaldi/egs/swbd/s5c/exp/nnet-dnn_5_1500_1024_0.002_0
lang=/mnt/jyhou/kaldi/egs/swbd/s5c/data/lang

# calculate mfcc
if [ $stage -le 1 ]; then
    utils/copy_data_dir.sh  $data_src $data_mfcc; rm $data_mfcc/{feats,cmvn}.scp
    steps/make_mfcc.sh --cmd "$train_cmd" --nj 20 $data_mfcc $data_mfcc/log $data_mfcc/data
    steps/compute_cmvn_stats.sh $data_mfcc $data_mfcc/log $data_mfcc/data
    utils/fix_data_dir.sh $data_mfcc
fi

# ali using gmm model
if [ $stage -le 2 ]; then
    steps/align_fmllr.sh --nj 20 --cmd "$train_cmd" \
        $data_mfcc $lang $gmmdir exp/tri4_xiaoying_native_ali
    steps/get_train_ctm.sh $data_mfcc $lang exp/tri4_xiaoying_native_ali
fi

mkdir -p data/oov
grep replacing exp/tri4_xiaoying_native_ali/log/compile_graphs.*.log |cut -d" " -f3 |sort |uniq >data/oov/words.txt

# calculate fbank pitch
if [ $stage -le 2 ]; then
    utils/copy_data_dir.sh  $data_src $data_fbank; rm $data_fbank/{feats,cmvn}.scp
    steps/make_fbank_pitch.sh --cmd "$train_cmd" --nj 20 $data_fbank $data_fbank/log $data_fbank/data
    steps/compute_cmvn_stats.sh $data_fbank $data_fbank/log $data_fbank/data
fi

# ali using nn model
if [ $stage -le 3 ]; then
    steps/nnet/align.sh --nj 20 --cmd "$train_cmd" --align-to-lats "true" \
        $data_fbank $lang $nndir exp/nn_xiaoying_native_ali
    steps/get_train_ctm.sh $data_fbank $lang exp/nn_xiaoying_native_ali
fi
