#!/bin/bash
echo "$0 $@"
. ./cmd.sh
[ -f path.sh ] && . ./path.sh

stage=8
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

# prepare xiaoying's read afterme data and 
if [ $stage -le 3 ]; then
    bash local/prepare_xiaoying_read_afterme.sh

    mkdir -p data/read_after_me_test/
    python local/subset_data_dir.py data/xiaoying_test.list data/read_after_me_all/ data/read_after_me_test/
    utils/utt2spk_to_spk2utt.pl data/read_after_me_test/utt2spk > data/read_after_me_test/spk2utt
    utils/fix_data_dir.sh data/read_after_me_test

    mkdir -p data/read_after_me_train1/
    python local/subset_data_dir.py data/xiaoying_train1.list data/read_after_me_all/ data/read_after_me_train1/
    utils/utt2spk_to_spk2utt.pl data/read_after_me_train1/utt2spk > data/read_after_me_train1/spk2utt
    utils/fix_data_dir.sh data/read_after_me_train1
fi

# prepare xiaoying's read afterme data and 
if [ $stage -le 4 ]; then
    bash local/prepare_xiaoying_pronunciation_challenge.sh
fi

if [ $stage -le 8 ]; then
    local/swbd1_data_download.sh /mnt/jyhou/data/swbd1
    # local/swbd1_data_download.sh /mnt/matylda2/data/SWITCHBOARD_1R2 # BUT,

    # prepare SWBD dictionary first since we want to find acronyms according to pronunciations
    # before mapping lexicon and transcripts
    local/swbd1_prepare_dict.sh

    # Prepare Switchboard data. This command can also take a second optional argument
    # which specifies the directory to Switchboard documentations. Specifically, if
    # this argument is given, the script will look for the conv.tab file and correct
    # speaker IDs to the actual speaker personal identification numbers released in
    # the documentations. The documentations can be found here:
    # https://catalog.ldc.upenn.edu/docs/LDC97S62/
    # Note: if you are using this link, make sure you rename conv_tab.csv to conv.tab
    # after downloading.
    # Usage: local/swbd1_data_prep.sh /path/to/SWBD [/path/to/SWBD_docs]
    local/swbd1_data_prep.sh /mnt/jyhou/data/swbd1


    # Data preparation and formatting for eval2000 (note: the "text" file
    local/eval2000_data_prep.sh /mnt/jyhou/data/Hub5Eval00/Hub5Eval00 /mnt/jyhou/data/Hub5Eval00/Hub5Eval00

    # Now make FBANK features.
    for x in train eval2000; do
      data_src=data/$x
      data_fbank=fbank/$x
      utils/copy_data_dir.sh $data_src $data_fbank; #rm $data_fbank/{feats,cmvn}.scp
      steps/make_fbank.sh --cmd "$train_cmd" --nj 20 $data_fbank $data_fbank/log $data_fbank/data
      steps/compute_cmvn_stats.sh $data_fbank $data_fbank/log $data_fbank/data
      utils/fix_data_dir.sh $data_fbank
    done

        # Use the first 4k sentences as dev set.  Note: when we trained the LM, we used
    # the 1st 10k sentences as dev set, so the 1st 4k won't have been used in the
    # LM training data.   However, they will be in the lexicon, plus speakers
    # may overlap, so it's still not quite equivalent to a test set.
    utils/subset_data_dir.sh --first fbank/train 4000 fbank/train_dev # 5hr 6min
    n=$[`cat data/train/segments | wc -l` - 4000]
    utils/subset_data_dir.sh --last fbank/train $n fbank/train_nodev

    # Now-- there are 260k utterances (313hr 23min), and we want to start the
    # monophone training on relatively short utterances (easier to align), but not
    # only the shortest ones (mostly uh-huh).  So take the 100k shortest ones, and
    # then take 30k random utterances from those (about 12hr)
    utils/subset_data_dir.sh --shortest fbank/train_nodev 100000 fbank/train_100kshort
    utils/subset_data_dir.sh fbank/train_100kshort 30000 fbank/train_30kshort

    # Take the first 100k utterances (just under half the data); we'll use
    # this for later stages of training.
    utils/subset_data_dir.sh --first fbank/train_nodev 100000 fbank/train_100k
    utils/data/remove_dup_utts.sh 200 fbank/train_100k fbank/train_100k_nodup  # 110hr

    # Finally, the full training set:
    utils/data/remove_dup_utts.sh 300 data-fbank/train_nodev data-fbank/train_nodup  # 286hr
  
fi

# extract fbank feature
if [ $stage -le 6 ]; then
    for x in read_after_me_test read_after_me_train1 pronunciation_challenge;
    do
        data_src=data/$x
        data_fbank=fbank/$x
        utils/copy_data_dir.sh  $data_src $data_fbank; rm $data_fbank/{feats,cmvn}.scp
        steps/make_fbank.sh --cmd "$train_cmd" --nj 20 $data_fbank $data_fbank/log $data_fbank/data
        steps/compute_cmvn_stats.sh $data_fbank $data_fbank/log $data_fbank/data
    done
fi

# do aliment using nn n
if [ $stage -le 7 ]; then
    gmmdir=/mnt/jyhou/kaldi/egs/swbd/s5c/exp/tri4
    nndir=exp/swbd_xy_200_train-nnet5uc-part2
    lang=/mnt/jyhou/kaldi/egs/swbd/s5c/data/lang

    for x in read_after_me_test;
    do
        data_fbank=fbank/$x
        steps/nnet/align.sh --use-gpu yes --nj 4 --cmd "$train_cmd" --align-to-lats "true" \
            $data_fbank $lang $nndir exp/nn_xiaoying_${x}_ali
        steps/get_train_ctm.sh $data_fbank $lang exp/nn_xiaoying_${x}_ali
    done

    for x in read_after_me_train1 pronunciation_challenge;
    do
        data_fbank=fbank/$x
        steps/nnet/align.sh --use-gpu yes --nj 4 --cmd "$train_cmd" \
            $data_fbank $lang $nndir exp/nn_xiaoying_${x}_ali
    done
fi

if [ $stage -le 8 ]; then
    for x in read_after_me_train1 pronunciation_challenge;
    do
        source_fbank=fbank/${x}
        if [ $x = "read_after_me_train1" ]; then
            word_score_pkl=data/info/word_score_read_after_me_all.pkl
            target_fbank=fbank/xiaoying_train1
        fi

        if [ $x = "pronunciation_challenge" ]; then
            word_score_pkl=data/info/word_score_pronunciation_challenge.pkl
            target_fbank=fbank/xiaoying_train2
        fi 
        mkdir -p $target_fbank
        echo "python local/select_utterances_by_score.py $word_score_pkl $source_fbank/wav.scp 10 100 $target_fbank/wav_selected.scp"
        python local/select_utterances_by_score.py $word_score_pkl $source_fbank/wav.scp 10 100 $target_fbank/wav_selected.scp
        utils/subset_data_dir.sh --utt-list $target_fbank/wav_selected.scp $source_fbank $target_fbank
    done
fi

if [ $stage -le 9 ]; then
    for dir in xiaoying_train1 xiaoying_train2;
    do
        utils/data/remove_dup_utts.sh 200 fbank/$dir fbank/${dir}_nodup_200
        utils/data/remove_dup_utts.sh 100 fbank/$dir fbank/${dir}_nodup_100
    done
    
    local/merge_data.sh fbank/xiaoying_train1_nodup_200 fbank/xiaoying_train2_nodup_200 fbank/xiaoying_train_nodup_200
    local/merge_data.sh fbank/xiaoying_train1_nodup_100 fbank/xiaoying_train2_nodup_100 fbank/xiaoying_train_nodup_100
    
    for dir in train_nodup xiaoying_train_nodup_200 xiaoying_train_nodup_100;
    do
        utils/subset_data_dir_tr_cv.sh fbank/$dir fbank/${dir}_tr90 fbank/${dir}_cv10
    done
    
    local/merge_data.sh fbank/train_nodup_tr90 fbank/xiaoying_train_nodup_100_tr90 fbank/swbd_xy_train_nodup_100_tr90
    local/merge_data.sh fbank/train_nodup_tr90 fbank/xiaoying_train_nodup_200_tr90 fbank/swbd_xy_train_nodup_200_tr90

    local/merge_data.sh fbank/train_nodup_cv10 fbank/xiaoying_train_nodup_100_cv10 fbank/swbd_xy_train_nodup_100_cv10
    local/merge_data.sh fbank/train_nodup_cv10 fbank/xiaoying_train_nodup_200_cv10 fbank/swbd_xy_train_nodup_200_cv10
fi
# extract keywords' instances from xiaoying native speaker data
if [ $stage -le 0 ]; then
    local/prepare_keywords_instances.sh
fi

# prepare STD test set from read_after_me_test set 
if [ $stage -le 0 ]; then
    echo "hou"
fi


# prepare STD non-native keywords from read_after_me_test set
# here we exclude the utterances which have been used for STD test
if [ $stage -le 0 ]; then
    echo "hou"
fi

# prepare xiaoying's STD dataset for STD experiments
if [ $stage -le 0 ]; then
    echo "hou"
fi


if [ $stage -le 0 ]; then
    bash local/run_train_sbnf.sh
fi

if [ $stage -le 0 ]; then
    bash local/run_train_sbnf_transfer.sh
fi
