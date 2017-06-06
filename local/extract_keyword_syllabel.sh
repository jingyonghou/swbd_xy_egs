mkdir -p data/text_keywords
tail -n 500 data/local/xiaoying_native/text_fixed.txt > data/info/text_fixed_tail_500
head -n 618 data/local/xiaoying_native/text_fixed.txt > data/info/text_fixed_head_618

python ./local/extract_keyword_syllabel.py data/info/syll.dict data/info/text_fixed_tail_500 data/text_keywords/unigram.list data/text_keywords/bigram.list

cat data/text_keywords/unigram.list |sort |uniq > data/text_keywords/unigram_sorted.list
cat data/text_keywords/bigram.list |sort |uniq > data/text_keywords/bigram_sorted.list
