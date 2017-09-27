#!/bin/bash

. ./cmd.sh
. ./path.sh

export LC_ALL=C
state=3
lang_test="data/lang_sw1_tg"
keywords_dir="data/lat_keywords"
oov=0
mkdir -p $keywords_dir
# build keyword lattice (linear word lattice)
if [ $state -le 1 ]; then
    lang="data/lang_nosp"

    cat info/keywords.list | sed s":-: :" > info/keywords.tras.raw

    oov=`cat $lang/oov.int` || exit 1;
    tras=$keywords_dir/keywords.tras
    paste info/keywords.list info/keywords.tras.raw |sort > $tras
    utils/sym2int.pl --map-oov $oov -f 2- $lang/words.txt \
        $keywords_dir/keywords.tras > $keywords_dir/keywords.tras.int

    tras=$keywords_dir/keywords.tras.int
    fsts=$keywords_dir/keywords.fsts
    transcripts-to-fsts ark:$tras ark:$fsts
fi

# get the lattice for the test data
gmm_dir=exp/tri4
nnet_dir=exp/xiaoying_train_nodup_200_4096_0.0005_0.9-nnet5uc-part2
graph_dir=$gmm_dir/graph_sw1_tg
nj=20
use_gpu=no
if [ $state -le 2 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
        data_dir=fbank/$x
        decode_dir=$nnet_dir/decode_$x
        steps/nnet/decode.sh --nj $nj --use-gpu $use_gpu $graph_dir $data_dir $decode_dir
    done
fi

# here we prepare the result file according to the best path
syllable_num_file="info/keyword_syllable_num.txt"
keyword_list_file="info/keywords.list"
asr_dir="/home/disk1/jyhou/my_code/XY_Text_STD/data_swbd"
if [ $state -le 3 ]; then

    for x in data_15_30 data_40_55 data_65_80;
    do
       result_dir=results/${x}_best/
       mkdir -p $result_dir
       asr_out=$asr_dir/${x}.text
       python local/prepare_asr_score.py $keyword_list_file $asr_out $result_dir
    done
fi

# evaluate
keyword_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
data_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
text_file="info/text_fixed_tail_500"
syllable_num_file="info/keyword_syllable_num.txt"
keyword_list_file="info/keywords.list"

if [ $state -le 4 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
       result_dir=results/${x}_best/
       test_list_file=$asr_dir/${x}.text
       echo $result_dir
       echo "python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file"
             python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file
    done
fi

