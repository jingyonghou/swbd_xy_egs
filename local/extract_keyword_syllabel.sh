mkdir -p data/text_keywords
python ./local/extract_keyword_syllabel.py data/info/syll.dict /mnt/jyhou/workspace/my_code/Prepare_windows_data/xiaoying_native/text_fixed_tail_500 data/text_keywords/unigram.list data/text_keywords/bigram.list

cat data/text_keywords/unigram.list |sort |uniq > data/text_keywords/unigram_sorted.list
cat data/text_keywords/bigram.list |sort |uniq > data/text_keywords/bigram_sorted.list
