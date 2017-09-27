#!/bin/bash

. ./cmd.sh
. ./path.sh

export LC_ALL=C
state=6
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
#nnet_dir=exp/swbd_4096_0.00006_0.9_original-nnet5uc-part2
graph_dir=$gmm_dir/graph_sw1_tg
nj=20
use_gpu=no
if [ $state -le 2 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
        data_dir=fbank/$x
        decode_dir=$nnet_dir/decode_$x
        steps/nnet/decode.sh --stage 2 --scoring-opts \
            "--min-lmwt 4 --max-lmwt 24" --nj $nj \
            --use-gpu $use_gpu $graph_dir $data_dir $decode_dir
    done
fi

# indexing
if [ $state -le 3 ]; then
    echo "Make Index..."
    for x in data_15_30 data_40_55 data_65_80;
    do
        test_dir=fbank/$x
        decode_dir=$nnet_dir/decode_$x

        cat $test_dir/feats.scp | awk '{print $1}' | sort | uniq | \
            perl -e '
              $idx=1;
              while(<>) {
                chomp;
                print "$_ $idx\n";
                $idx++;
              }' > $test_dir/utter_id

        steps/make_index.sh --cmd "$decode_cmd" \
        $test_dir ${lang_test} \
        ${decode_dir} \
        ${decode_dir}/kws
    done
fi

# searching keywords from index
if [ $state -le 4 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
        decode_dir=$nnet_dir/decode_$x
        time steps/search_index.sh --cmd "$decode_cmd" \
            $keywords_dir \
            ${decode_dir}/kws
    done
fi

# prepare result file for evaluation
feat_dir=fbank
keyword_list_file="info/keywords.list"
if [ $state -le 5 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
        decode_dir=$nnet_dir/decode_$x
        utter_id_file=$feat_dir/$x/utter_id
        result_dir=results/${x}_lattice
        rm -r $result_dir
        mkdir -p $result_dir
        cat $decode_dir/kws/result.*.gz | gunzip -c > $decode_dir/kws/result.txt
        python local/prepare_lattice_score.py $decode_dir/kws/result.txt \
            $keyword_list_file $utter_id_file $result_dir
    done
fi


#evaluate
keyword_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
data_list_dir="/mnt/jyhou/feats/XiaoYing_STD/list/"
text_file="info/text_fixed_tail_500"
syllable_num_file="info/keyword_syllable_num.txt"
keyword_list_file="info/keywords.list"

if [ $state -le 6 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
       result_dir=results/${x}_lattice/
       test_list_file=$feat_dir/$x/utter_id
       echo $result_dir
       echo "python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file"
             python local/evaluate.py $result_dir $keyword_list_file $test_list_file $text_file $syllable_num_file
    done
fi

