import sys
import numpy as np
import log
import re

MINIMUM_PHONE=5
MINIMUM_SYLL=2
MINIMUM_OCCUR=3

def build_oov_list(oov_file):
    oov_list=[]
    for oov in open(oov_file).readlines():
        oov_list.append(oov.strip())
    return oov_list

def build_syllable_dictionary(dictionary_file):
    syllable_num_dict = {}
    for line in open(dictionary_file).readlines():
        fields = line.strip().split()
        word_id = fields[0]
        phone_fields = re.split('\.|-', fields[1])
        syll_fields = fields[1].split("-")
        syllable_num_dict[word_id]=[len(syll_fields), len(phone_fields)]
    return syllable_num_dict

def build_unigram_keyword_fq_dict(text_file, syllable_num_dict):
    id_with_transcription_list=open(text_file).readlines()
    unigram_keyword_dict={}
    for item in id_with_transcription_list:
        fields = item.strip().split()
        words=fields[2:]
        for word in words:
            if not syllable_num_dict.has_key(word.upper()):
                print("Warning: there is no keyword %s in the syllable dictionary"%word)
                continue
            if syllable_num_dict[word.upper()][0] >= MINIMUM_SYLL and syllable_num_dict[word.upper()][1] >= MINIMUM_PHONE :
                if unigram_keyword_dict.has_key(word):
                    unigram_keyword_dict[word] += 1
                else:
                    unigram_keyword_dict[word] = 1
    return unigram_keyword_dict

def build_bigram_keyword_fq_dict(text_file, syllable_num_dict):
    id_with_transcription_list=open(text_file).readlines()
    bigram_keyword_dict={}
    for item in id_with_transcription_list:
        fields = item.strip().split()
        words=fields[2:]
        for i in range(len(words)-1):
            phrase = words[i] + " " + words[i+1]
            if (syllable_num_dict[words[i].upper()][1] + syllable_num_dict[words[i+1].upper()][1]) >= MINIMUM_PHONE:
                if bigram_keyword_dict.has_key(phrase):
                    bigram_keyword_dict[phrase] += 1
                else:
                    bigram_keyword_dict[phrase] = 1
    return bigram_keyword_dict
            
if __name__=="__main__":
    if len(sys.argv) < 4:
        print("UDAGE: python "+ sys.argv[0]+ " syllabel_dict_file text keyword_file keyphrase_file")
        exit(1)
    syllable_num_dict = build_syllable_dictionary(sys.argv[1])
    unigram_keyword_dict = build_unigram_keyword_fq_dict(sys.argv[2], syllable_num_dict)
    bigram_keyword_dict = build_bigram_keyword_fq_dict(sys.argv[2], syllable_num_dict)

    fid1 = open(sys.argv[3], "w") 
    fid2 = open(sys.argv[4], "w") 
    
    # build unigram keyword
    count=0
    for word in unigram_keyword_dict.keys():
        if (unigram_keyword_dict[word] >= MINIMUM_OCCUR):
            sylla_num = syllable_num_dict[word.upper()][0]
            phone_num = syllable_num_dict[word.upper()][1]
            
            fid1.writelines("%s\t%d\t%d\t%d\n"%(word, sylla_num, phone_num, unigram_keyword_dict[word]))
            count += 1
    unigram_num = count
    fid1.close()
    count=0
    for phrase in bigram_keyword_dict.keys():
        if (bigram_keyword_dict[phrase] >= MINIMUM_OCCUR + 1):
            words = phrase.split() 
            sylla_num = syllable_num_dict[words[0].upper()][0]
            phone_num = syllable_num_dict[words[0].upper()][1]
            sylla_num += syllable_num_dict[words[1].upper()][0]
            phone_num += syllable_num_dict[words[1].upper()][1]
            
            fid2.writelines("%s\t%d\t%d\t%d\n"%(phrase, sylla_num, phone_num, bigram_keyword_dict[phrase]))
            count += 1
    bigram_num = count 
    print("the suitable unigram number: %d, bigram number: %d, total number: %d\n"%(unigram_num, bigram_num, unigram_num+bigram_num))
    fid2.close()
