keyword_list=data/info/keywords.list
text=/mnt/jyhou/workspace/my_code/Prepare_windows_data/xiaoying_native/text_fixed_tail_500

for x in data_15_30 data_40_55 data_65_80;
do
    scp_file=data/$x/text
    keyword_occurance_summery=${x}_keyword_occurance_summery.txt
    sentence_summery=${x}_sentence_summery.txt
    echo "python local/calculate_keyword_occurance_in_search_dataset.py $keyword_list $text $scp_file $keyword_occurance_summery $sentence_summery"
    python local/calculate_keyword_occurance_in_search_dataset.py $keyword_list $text $scp_file $keyword_occurance_summery $sentence_summery
done
