#!/bin/bash
echo "$0 $@"
. ./cmd.sh
[ -f path.sh ] && . ./path.sh

stage=1
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

# extract keywords' instances from xiaoying native speaker data
if [ $stage -le 4 ]; then
    local/prepare_keywords_instances.sh;
fi

# prepare STD test set from read_after_me_test set 
if [ $stage -le 5 ]; then
;
fi


# prepare STD non-native keywords from read_after_me_test set
# here we exclude the utterances which have been used for STD test
if [ $stage -le 6 ]; then
;
fi

# prepare xiaoying's STD dataset for STD experiments
if [ $stage -le 7 ]; then
;
fi








