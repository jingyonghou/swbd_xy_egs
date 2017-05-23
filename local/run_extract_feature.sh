. ./cmd.sh
[ -f path.sh ] && . ./path.sh
stage=19
# extract mfcc feature
fea_dir=/mnt/jyhou/feats/XiaoYing_STD
mfcc_dir=mfcc
if [ $stage -le 17 ]; then
    for x in data_15_30 data_40_55 data_65_80 keywords_20_60 keywords_60_100 keywords_native;
    do
        utils/copy_data_dir.sh  data/$x $mfcc_dir/$x; rm $mfcc_dir/$x/{feats,cmvn}.scp
        steps/make_mfcc.sh --cmd "$train_cmd" --nj 20 $mfcc_dir/$x $mfcc_dir/$x/log $mfcc_dir/$x/data
        steps/compute_cmvn_stats.sh $mfcc_dir/$x $mfcc_dir/$x/log $mfcc_dir/$x/data

        mkdir -p ${fea_dir}/${x}
        copy-feats-to-htk  --output-dir=${fea_dir}/${x} \
            --output-ext=mfcc ark:"copy-feats scp:$mfcc_dir/$x/feats.scp ark:-|add-deltas ark:- ark:|"
    done
fi

# extract fbank feature
fea_dir=/mnt/jyhou/feats/XiaoYing_STD
fbank_dir=fbank
if [ $stage -le 18 ]; then
    for x in data_15_30 data_40_55 data_65_80 keywords_20_60 keywords_60_100 keywords_native;
    do
        utils/copy_data_dir.sh  data/$x $fbank_dir/$x; rm $fbank_dir/$x/{feats,cmvn}.scp
        steps/make_fbank.sh --cmd "$train_cmd" --nj 20 \
                       $fbank_dir/$x $fbank_dir/$X/log $fbank_dir/$x/data || exit 1;
        steps/compute_cmvn_stats.sh $fbank_dir/$x $fbank_dir/$x/log $fbank_dir/$x/data || exit 1;
    done

fi

# extract sbnf from SWBD model
#nnet=exp/xiaoying_train_nodup_100_4096_0.0005_0-nnet5uc-part2/
#nnet=exp/xiaoying_train_nodup_200_4096_0.0005_0-nnet5uc-part2/
#nnet=exp/swbd_xy_train_nodup_100-nnet5uc-part2/
#nnet=exp/swbd_xy_train_nodup_200-nnet5uc-part2/
nnet=exp/xiaoying_train_nodup_100-nnet5uc-part2/

if [ $stage -le 19 ]; then
    for x in data_15_30 data_40_55 data_65_80 keywords_20_60 keywords_60_100 keywords_native;
    do
        sbnf="sbnf2"
        bn_dir=$sbnf/$x
        mkdir -p $bn_dir
        steps/nnet/make_bn_feats.sh --cmd "$train_cmd" --use-gpu yes --nj 4 $bn_dir $fbank_dir/$x $nnet $bn_dir/log $bn_dir/data
        copy-feats-to-htk --output-dir=${fea_dir}/$x --output-ext=$sbnf  scp:$bn_dir/feats.scp
    done
fi

# decode xiaoying STD's search data
gmmdir=/mnt/jyhou/kaldi/egs/swbd/s5c/exp/tri4
graphdir=$gmmdir/graph_sw1_tg
nnetdir=exp/train_nodup-nnet5uc-part2/
#nnet=exp/xiaoying_train_nodup_100_4096_0.0005_0-nnet5uc-part2/
#nnet=exp/xiaoying_train_nodup_200_4096_0.0005_0-nnet5uc-part2/
#nnet=exp/swbd_xy_train_nodup_100-nnet5uc-part2/
#nnet=exp/swbd_xy_train_nodup_200-nnet5uc-part2/
if [ $stage -le 0 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
        data_dir=fbank/data_$x
        decode_dir=$nnetdir/$x
        local/decode_xiaoying.sh $data_dir $gmmdir $graphdir $decode_dir
    done
fi

