import sys

text_raw_uniq_file = sys.argv[1]

one_word_sentence_num=0
two_word_sentence_num=0
tri_word_sentence_num=0
for line in open(text_raw_uniq_file).readlines():
    fields = line.strip().split()
    if len(fields)==1:
        one_word_sentence_num += 1 
    elif len(fields)==2:
        two_word_sentence_num += 1 
    elif len(fields)==3:
        tri_word_sentence_num += 1
print("one word sentence num:%d, two words sentence num:%d, three words sentence num:%d \n"%(one_word_sentence_num,two_word_sentence_num,tri_word_sentence_num))

