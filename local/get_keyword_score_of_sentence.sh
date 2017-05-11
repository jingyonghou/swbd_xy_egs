word_score_dict_file=data/info/word_score_read_after_me_all.pkl
keywords_list=data/info/keywords.list
test_scp=data/read_after_me_test/wav.scp
text_tail_500=/mnt/jyhou/workspace/my_code/Prepare_windows_data/xiaoying_native/text_fixed_tail_500

#python local/get_keyword_score_of_sentence.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 15 30 keyword_score_15_30.txt
#python local/get_keyword_score_of_sentence.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 40 55 keyword_score_40_55.txt
#python local/get_keyword_score_of_sentence.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 65 80 keyword_score_65_80.txt
python local/get_keyword_score_of_sentence.py $word_score_dict_file $keywords_list $test_scp $text_tail_500 0 100 keyword_score_0_100.txt
