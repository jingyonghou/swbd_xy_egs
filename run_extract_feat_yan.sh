. ./cmd.sh
. ./path.sh
stage=18
fbank_dir=fbank_yan
mkdir -p $fbank_dir
if [ $stage -le 18 ]; then
    for x in keywords tests;
    do
        utils/copy_data_dir.sh  yan/$x $fbank_dir/$x; rm $fbank_dir/$x/{feats,cmvn}.scp
        steps/make_fbank.sh --cmd "$train_cmd" --nj 1 \
                       $fbank_dir/$x $fbank_dir/$x/log $fbank_dir/$x/data || exit 1;
        steps/compute_cmvn_stats.sh $fbank_dir/$x $fbank_dir/$x/log $fbank_dir/$x/data || exit 1;
    done

fi

fea_dir=/home/disk1/jyhou/test/casesfromxiayan
nnet=exp/xiaoying_train_nodup_200_4096_0.0005_0.9-nnet5uc-part2/
if [ $stage -le 19 ]; then
    for x in keywords tests;
    do
        sbnf="sbnf1"
        bn_dir=$sbnf/$x
        mkdir -p ${fea_dir}/$x
        mkdir -p $bn_dir
        steps/nnet/make_bn_feats.sh --cmd "$train_cmd" --nj 1 $bn_dir $fbank_dir/$x $nnet $bn_dir/log $bn_dir/data
        copy-feats-to-htk --output-dir=${fea_dir}/$x --output-ext=$sbnf  scp:$bn_dir/feats.scp
    done
fi

