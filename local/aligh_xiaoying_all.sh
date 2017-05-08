. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

. ./path.sh ## Source the tools/utils (import the queue.pl)
stage=3
gmmdir=/mnt/jyhou/kaldi/egs/swbd/s5c/exp/tri4
nndir=exp/swbd_xy_200_train-nnet5uc-part2
lang=/mnt/jyhou/kaldi/egs/swbd/s5c/data/lang

for x in read_after_me_test read_after_me_train1;
do
    data_src=data/$x
    data_mfcc=mfcc/$x
    data_fbank=fbank/$x
    if [ $stage -le 2 ]; then
        utils/copy_data_dir.sh  $data_src $data_fbank; rm $data_fbank/{feats,cmvn}.scp
        steps/make_fbank.sh --cmd "$train_cmd" --nj 20 $data_fbank $data_fbank/log $data_fbank/data
        steps/compute_cmvn_stats.sh $data_fbank $data_fbank/log $data_fbank/data
    fi

    # ali using nn model
    if [ $stage -le 3 ]; then
        steps/nnet/align.sh --nj 20 --cmd "$train_cmd" --align-to-lats "true" \
            $data_fbank $lang $nndir exp/nn_xiaoying_${x}_ali
        steps/get_train_ctm.sh $data_fbank $lang exp/nn_xiaoying_${x}_ali
    fi
done
