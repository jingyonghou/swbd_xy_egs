#!/bin/bash

. ./cmd.sh
. ./path.sh
stage=1
nj=20

nnet_forward_opts="--no-softmax=true --prior-scale=1.0"
use_gpu=yes
nnet_dir=exp/xiaoying_train_nodup_200_4096_0.0005_0.9-nnet5uc-part2/
# do the net forward
if [ $stage -le 0 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
        data_dir=fbank/$x
        decode_dir=$nnet_dir/$x
        local/nnet_acoustic_forward.sh --use-gpu $use_gpu $nnet_dir $data_dir $decode_dir
    done
fi
# make graph
#build decode graph for each keyword
nj=20
model_dir=$nnet_dir
decode_dir="exp/decode_akws"
if [ $stage -le 1 ]; then
    export LC_ALL=C
    lang="data/lang_nosp"
    mkdir -p $decode_dir

    cp $model_dir/tree $decode_dir/tree
    cp $model_dir/final.mdl $decode_dir/final.mdl
    cp $model_dir/cmvn_opts $decode_dir/cmvn_opts
    cat info/keywords.list | sed s":-: :" > info/keywords.tras.raw

    oov=`cat $lang/oov.int` || exit 1;
    tras=$decode_dir/keywords.tras
    paste info/keywords.list info/keywords.tras.raw |sort > $tras
    utils/sym2int.pl --map-oov $oov -f 2- $lang/words.txt \
        $decode_dir/keywords.tras > $decode_dir/keywords.tras.int

    tras=$decode_dir/keywords.tras.int
    mkdir -p tmp/
    python local/split.py $tras tmp/ $nj
    graphs=$decode_dir/graphs.JOB.fsts
    run.pl JOB=1:$nj log/make_keywords_graphs.JOB.log \
        compile-keyword-graphs --read-disambig-syms=$lang/phones/disambig.int \
        $decode_dir/tree $decode_dir/final.mdl $lang/phones/align_lexicon.int \
        "ark:tmp/keywords.tras.intJOB" ark:$graphs
fi
# do the iterative decode of akws
feature_dir=$model_dir
decode_tool=iterating-viterbi-decoding-mapped
if [ $stage -le 2 ]; then
    for x in data_15_30 data_40_55 data_65_80; do
        result_dir=results/${x}_keywords_60_100_tri
        mkdir -p $result_dir
        local/akws_i.sh --scale_opts \
            "--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1" \
            --nj $nj --decode-tool $decode_tool \
            $feature_dir/$x $decode_dir $result_dir
    done
fi

#evaluate
keyword_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
data_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
text_file="info/text_fixed_tail_500"
syllable_num_file="info/keyword_syllable_num.txt"
keyword_list_file="info/keywords.list"

if [ $stage -le 3 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do

       result_dir=results/${x}_keywords_60_100_tri/
       test_list_file=$feature_dir/$x/likehood.scp
       echo $result_dir
       echo "python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file"
             python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file
    done
fi

