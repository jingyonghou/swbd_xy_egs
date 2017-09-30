#!/bin/bash
echo "$0 $@"
. ./cmd.sh
[ -f path.sh ] && . ./path.sh

stage=17
# prepare swbd data
if [ $stage -le 5 ]; then
    ln -s /home/disk1/jyhou/kaldi/egs/swbd/s5c/data data  
fi
# prepare xiaoying native data
# here we split the the data into 2 set, test and train1 according to the text of this data
# last 500 setences are used to extract keywords and first 618 sentence are used for training
if [ $stage -le 1 ]; then
    bash local/prepare_xiaoying_native.sh
fi

# prepare keywords
# after this we select some keywords by hands
# (we remove several people's name and some 
# keywords with simillar pronounciation, for 
# bigram keywords we preseve some resonable 
# phrases finally we preserve 60 unigram keywords and 20 bigram keywords)
if [ $stage -le 2 ]; then
    bash local/extract_keyword_syllabel.sh
fi

# prepare xiaoying's read afterme data and split it by text 
if [ $stage -le 3 ]; then
    bash local/prepare_xiaoying_read_afterme.sh

    mkdir -p data/read_after_me_test/
    python local/subset_data_dir.py data/info/text_fixed_tail_500 data/read_after_me_all/ data/read_after_me_test/
    utils/utt2spk_to_spk2utt.pl data/read_after_me_test/utt2spk > data/read_after_me_test/spk2utt
    utils/fix_data_dir.sh data/read_after_me_test

    mkdir -p data/read_after_me_train1/
    python local/subset_data_dir.py data/info/text_fixed_head_618 data/read_after_me_all/ data/read_after_me_train1/
    utils/utt2spk_to_spk2utt.pl data/read_after_me_train1/utt2spk > data/read_after_me_train1/spk2utt
    utils/fix_data_dir.sh data/read_after_me_train1


fi

# prepare xiaoying's read afterme data and 
if [ $stage -le 4 ]; then
    bash local/prepare_xiaoying_pronunciation_challenge.sh
fi

#split the xiaoying's data by speaker 
if [ $stage -le 4 ]; then
    python local/get_read_afterme_speaker.py info/read_after_me_json.list xy_data/read_after_me_train1/wav.scp info/read_afterme_train_speaker.list
    python local/get_read_afterme_speaker.py info/read_after_me_json.list xy_data/read_after_me_test/wav.scp info/read_afterme_test_speaker.list
    python local/get_pronunciation_challenge_speaker.py xy_data/pronunciation_challenge/wav.scp info/pronunciation_challenge_train_speaker.list

    cat info/read_afterme_train_speaker.list info/read_afterme_test_speaker.list |sort|uniq >  info/read_afterme_all_speaker.list
    #python local/shuffle_list.py data/info/read_afterme_all_speaker.list data/info/read_afterme_all_speaker_shuffled.list
    #head -n 4000 data/info/read_afterme_all_speaker_shuffled.list > data/info/speaker_train1.list
    #tail -n 4198 data/info/read_afterme_all_speaker_shuffled.list > data/info/speaker_test.list
    
    python local/exclude_list.py info/search_data_speaker.list info/read_afterme_all_speaker.list info/read_afterme_remain_speaker.list

    python local/shuffle_list.py info/read_afterme_remain_speaker.list info/read_afterme_remain_speaker_shuffled.list 777

    total_num=`cat info/read_afterme_remain_speaker_shuffled.list |wc -l`
    train_num=5000
    extract_num=$((total_num-train_num))
    head -n $train_num info/read_afterme_remain_speaker_shuffled.list > data/info/speaker_train1.list
    tail -n $extract_num info/read_afterme_remain_speaker_shuffled.list > data/info/speaker_test1.list

    cat info/speaker_test1.list info/search_data_speaker.list > info/speaker_test.list

    cat info/speaker_train1.list info/pronunciation_challenge_train_speaker.list > info/speaker_train_all.list 
    # this still contains little part of test speaker because some pronunciation challenge data may contains the test speaker
    python local/exclude_list.py info/speaker_test.list info/speaker_train_all.list info/speaker_train.list

    python local/exclude_list_by_speaker.py info/read_after_me_json.list info/speaker_train.list xy_data/read_after_me_test/wav.scp info/read_afterme_test_remain.scp

    python local/exclude_list_by_speaker.py info/read_after_me_json.list info/speaker_test.list xy_data/read_after_me_train1/wav.scp info/read_afterme_train1_remain.scp
    
    python local/exclude_list_by_speaker_pronunciation.py info/speaker_test.list xy_data/pronunciation_challenge/wav.scp info/pronunciation_challenge_remain.scp
    
    utils/subset_data_dir.sh --utt-list info/read_afterme_test_remain.scp xy_data/read_after_me_test xy_data/read_after_me_test_remain
    utils/subset_data_dir.sh --utt-list info/read_afterme_train1_remain.scp xy_data/read_after_me_train1 xy_data/read_after_me_train1_remain
    utils/subset_data_dir.sh --utt-list info/pronunciation_challenge_remain.scp xy_data/pronunciation_challenge xy_data/pronunciation_challenge_remain
    
fi

if [ $stage -le 8 ]; then
    for x in read_after_me_train1_remain pronunciation_challenge_remain;
    do
        source_data=xy_data/${x}
        if [ $x = "read_after_me_train1_remain" ]; then
            word_score_pkl=info/read_after_me_score.pkl
            target_data=xy_data/xiaoying_train1
        fi

        if [ $x = "pronunciation_challenge_remain" ]; then
            word_score_pkl=info/pronunciation_challenge_score.pkl
            target_data=xy_data/xiaoying_train2
        fi 
        mkdir -p $target_data
        echo "python local/select_utterances_by_score.py $word_score_pkl $source_data/wav.scp 10 100 $target_data/wav_selected.scp"
        python local/select_utterances_by_score.py $word_score_pkl $source_data/wav.scp 10 100 $target_data/wav_selected.scp
        utils/subset_data_dir.sh --utt-list $target_data/wav_selected.scp $source_data $target_data
    done
fi

# extract fbank feature
if [ $stage -le 6 ]; then
    for x in xiaoying_train1 xiaoying_train2;
    do
        data_src=xy_data/$x
        data_fbank=fbank/$x
        utils/copy_data_dir.sh  $data_src $data_fbank; rm $data_fbank/{feats,cmvn}.scp
        steps/make_fbank.sh --cmd "$train_cmd" --nj 20 $data_fbank $data_fbank/log $data_fbank/data
        steps/compute_cmvn_stats.sh $data_fbank $data_fbank/log $data_fbank/data
    done
fi

# do aliment using nn n
if [ $stage -le 7 ]; then
    gmmdir=exp/tri4
    nndir=exp/swbd_4096_0.00006_0.9_original-nnet5uc-part2
    lang=data/lang

    for x in xiaoying_train1 xiaoying_train2;
    do
        data_fbank=fbank/$x
        steps/nnet/align.sh --use-gpu yes --nj 4 --cmd "$train_cmd" \
            $data_fbank $lang $nndir exp/nn_xiaoying_${x}_ali
    done

    
fi


if [ $stage -le 9 ]; then
    for dir in xiaoying_train1 xiaoying_train2;
    do
        utils/data/remove_dup_utts.sh 200 fbank/$dir fbank/${dir}_nodup_200
        utils/data/remove_dup_utts.sh 100 fbank/$dir fbank/${dir}_nodup_100
    done
    
    
    for dir in train_nodup xiaoying_train1_nodup_200 xiaoying_train1_nodup_100 xiaoying_train2_nodup_200 xiaoying_train2_nodup_100;
    do
        utils/subset_data_dir_tr_cv.sh fbank/$dir fbank/${dir}_tr90 fbank/${dir}_cv10
    done
    
    local/merge_data.sh fbank/xiaoying_train1_nodup_200_tr90 fbank/xiaoying_train2_nodup_200_tr90 fbank/xiaoying_train_nodup_200_tr90
    local/merge_data.sh fbank/xiaoying_train1_nodup_200_cv10 fbank/xiaoying_train2_nodup_200_cv10 fbank/xiaoying_train_nodup_200_cv10
    
    local/merge_data.sh fbank/xiaoying_train1_nodup_100_tr90 fbank/xiaoying_train2_nodup_100_tr90 fbank/xiaoying_train_nodup_100_tr90
    local/merge_data.sh fbank/xiaoying_train1_nodup_100_cv10 fbank/xiaoying_train2_nodup_100_cv10 fbank/xiaoying_train_nodup_100_cv10
    
    local/merge_data.sh fbank/train_nodup_tr90 fbank/xiaoying_train_nodup_100_tr90 fbank/swbd_xy_train_nodup_100_tr90
    local/merge_data.sh fbank/train_nodup_tr90 fbank/xiaoying_train_nodup_200_tr90 fbank/swbd_xy_train_nodup_200_tr90

    local/merge_data.sh fbank/train_nodup_cv10 fbank/xiaoying_train_nodup_100_cv10 fbank/swbd_xy_train_nodup_100_cv10
    local/merge_data.sh fbank/train_nodup_cv10 fbank/xiaoying_train_nodup_200_cv10 fbank/swbd_xy_train_nodup_200_cv10
fi

if [ $stage -le 0 ]; then
    bash local/run_train_sbnf.sh
fi

if [ $stage -le 0 ]; then
    bash local/run_train_sbnf_transfer.sh
fi

# extract keywords' instances from xiaoying native speaker data
if [ $stage -le 10 ]; then
    local/prepare_keywords_instances.sh
fi

# prepare STD test set from read_after_me_test set 
if [ $stage -le 11 ]; then
    echo "prepare STD test set from read_after_me_test set"
    word_score_dict_file=data/info/word_score_read_after_me_all.pkl
    keywords_list=data/info/keywords.list
    test_scp=data/read_after_me_test_remain/wav.scp
    text_tail_500=/mnt/jyhou/workspace/my_code/Prepare_windows_data/xiaoying_native/text_fixed_tail_500
    mkdir -p data/local/data_15_30
    python local/get_search_dataset.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 \
            15 30 10 40 2 data/local/data_15_30/utter.id
    mkdir -p data/local/data_40_55
    python local/get_search_dataset.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 \
            40 55 30 65 2 data/local/data_40_55/utter.id
    mkdir -p data/local/data_65_80
    python local/get_search_dataset.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 \
            65 80 55 100 2 data/local/data_65_80/utter.id
   
    for x in data_15_30 data_40_55 data_65_80;
    do
        source_dir=/mnt/jyhou/data/XiaoYing_All/
        target_dir=/mnt/jyhou/data/XiaoYing_STD/$x/
        echo "python local/copy_file.py data/local/$x/utter.id  $source_dir $target_dir \"wav\""
        python local/copy_file.py data/local/$x/utter.id  $source_dir $target_dir "wav"
    done
     
    
fi

if [ $stage -le 12 ]; then
    
    for x in data_15_30 data_40_55 data_65_80;
    do
        cat data/local/$x/utter.id || exit 1;
    done > data/info/search_data.list
    echo "python local/exclude_list.py data/info/search_data.list data/read_after_me_test/wav.scp data/info/read_after_me_test_exclude_search_data.scp "
    python local/exclude_list.py data/info/search_data.list data/read_after_me_test_remain/wav.scp data/info/read_after_me_test_exclude_search_data.scp 
fi

if [ $stage -le 13 ]; then
    word_score_dict_file=data/info/word_score_read_after_me_all.pkl
    keywords_list=data/info/keywords.list
    test_scp=data/info/read_after_me_test_exclude_search_data.scp
    text_tail_500=/mnt/jyhou/workspace/my_code/Prepare_windows_data/xiaoying_native/text_fixed_tail_500
    mkdir -p data/local/data_15_30_candidate
    python local/get_search_dataset.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 \
            15 30 10 40 3 data/local/data_15_30_candidate/utter.id
    mkdir -p data/local/data_40_55_candidate
    python local/get_search_dataset.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 \
            40 55 30 65 3 data/local/data_40_55_candidate/utter.id
    mkdir -p data/local/data_65_80_candidate
    python local/get_search_dataset.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 \
            65 80 55 100 3 data/local/data_65_80_candidate/utter.id
    
    for x in data_15_30 data_40_55 data_65_80;
    do
        source_dir=/mnt/jyhou/data/XiaoYing_All/
        target_dir=/mnt/jyhou/data/XiaoYing_STD/${x}_candidate/
        echo "python local/copy_file.py data/local/${x}_candidate/utter.id  $source_dir $target_dir \"wav\""
        python local/copy_file.py data/local/${x}_candidate/utter.id  $source_dir $target_dir "wav"
    done
fi

# after above step we select search dataset from above data_*_* and data_*_*_candidate by hand final search dateset is in data_*_*_final
if [ $stage -le 14 ]; then
    echo "prepare STD data"
    bash local/prepare_xiaoying_search_data.sh

    for x in data_15_30 data_40_55 data_65_80;
    do 
        cat data/$x/wav.scp ||exit 1;
    done > data/info/search_data_all.scp

    python local/get_read_afterme_speaker.py data/info/read_after_me_json.list data/info/search_data_all.scp data/info/search_data_speaker.list
    python local/exclude_list_by_speaker.py /mnt/jyhou/data/userTextAudio/json.list data/info/search_data_speaker.list data/read_after_me_test_remain/wav.scp data/info/extract_keywords.scp
fi
# prepare STD non-native keywords from read_after_me_test set
# here we exclude the utterances which have been used for STD test
if [ $stage -le 15 ]; then
    word_score_dict_file=data/info/word_score_read_after_me_all.pkl
    keywords_list=data/info/keywords.list
    test_scp=data/info/extract_keywords.scp #exclude search dataset
    cmt_file=exp/nn_xiaoying_read_after_me_test_ali/cmt

    out_dir=/mnt/jyhou/data/XiaoYing_STD/keywords_80_100/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 80 100 10 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 80 100 10 $out_dir 
    
    out_dir=/mnt/jyhou/data/XiaoYing_STD/keywords_60_100/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 100 10 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 100 10 $out_dir 

    out_dir=/mnt/jyhou/data/XiaoYing_STD/keywords_20_60/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 20 60 10 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 20 60 10 $out_dir 


    word_score_dict_file=data/info/word_score_xiaoying_native.pkl
    keywords_list=data/info/keywords.list
    test_scp=data/xiaoying_native/wav.scp #exclude search dataset
    cmt_file=exp/nn_xiaoying_native_ali

    out_dir=/mnt/jyhou/data/XiaoYing_STD/keywords_native/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 100 10 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 100 10 $out_dir 
        
fi

# after above we select keywords by hands

# prepare xiaoying's STD dataset for STD experiments
if [ $stage -le 16 ]; then
    echo "prepare STD keyword data"
    bash local/prepare_xiaoying_keywords.sh
fi


# ==========================================extract stack bottleneck features ========================================
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
nnet=exp/train_nodup-nnet5uc-part2/
if [ $stage -le 19 ]; then
    for x in data_15_30 data_40_55 data_65_80 keywords_20_60 keywords_60_100 keywords_native;
    do
        sbnf="sbnf0"
        bn_dir=$sbnf/$x
        mkdir -p $bn_dir
        steps/nnet/make_bn_feats.sh --cmd "$train_cmd" --nj 20 $bn_dir $fbank_dir/$x $nnet $bn_dir/log $bn_dir/data
        copy-feats-to-htk --output-dir=${fea_dir}/$x --output-ext=$sbnf  scp:$bn_dir/feats.scp
    done
fi

# decode xiaoying STD's search data

gmmdir=/mnt/jyhou/kaldi/egs/swbd/s5c/exp/tri4
graphdir=$gmmdir/graph_sw1_tg
nnetdir=exp/train_nodup-nnet5uc-part2/
if [ $stage -le 0 ]; then
    for x in data_15_30 data_40_55 data_65_80;
    do
        data_dir=fbank/data_$x
        decode_dir=$nnetdir/$x
        local/decode_xiaoying.sh $data_dir $gmmdir $graphdir $decode_dir
    done
fi

