state=1
# exclude the speaker from the search dataset
if [ $state -le 0 ]; then

fi
if [ $stage -le 1 ]; then
    word_score_dict_file=info/read_after_me_score.pkl
    keywords_list=info/isolatess.list
    test_scp=info/extract_keywords.scp #exclude search dataset
    cmt_file=exp/nn_xiaoying_read_after_me_test_ali/cmt

    out_dir=/mnt/jyhou/data/XiaoYing_STD/keywords_80_100/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 80 100 10 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 80 100 10 $out_dir 
    
    out_dir=/mnt/jyhou/data/XiaoYing_STD/keywords_60_100/
    mkdir -p $out_dir
    echo "python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 100 10 $out_dir "
    python local/get_keyword_instances.py $keywords_list $test_scp $word_score_dict_file $ctm_file 60 100 10 $out_dir 

fi
