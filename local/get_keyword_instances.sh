state=1
# exclude the speaker from the search dataset
if [ $state -le 0 ]; then
    python local/exclude_list_by_speaker.py info/read_after_me_json.list info/search_data_speaker.list xy_data/read_after_me_test_remain/wav.scp info/extract_keywords.scp

fi

if [ $state -le 1 ]; then
    word_score_dict_file=info/read_after_me_score.pkl
    keywords_list=info/isolates.list
    test_scp=info/extract_keywords.scp #exclude search dataset
    cmt_file=exp/nn_xiaoying_read_after_me_test_ali/cmt

    out_dir=/home/disk1/jyhou/data/XiaoYing_STD/keywords_80_100_50/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 80 100 50 0 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 80 100 50 0 $out_dir 
    
    out_dir=/home/disk1/jyhou/data/XiaoYing_STD/keywords_60_80_50/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 80 50 50 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 80 50 50 $out_dir 
fi
