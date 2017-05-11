import sys
import log
import pickle
import numpy as np
import wavedata
import random

DELAY=320
SAMPLERATE=8000
MAX_INTERVAL=1600

def build_keywords_list(keywords_list_file):
    keywords_list = []
    for line in open(keywords_list_file, "rb").readlines():
        keywords_list.append(line.strip())
    return keywords_list

def build_wav_scp_dict(wav_scp_file):
    wav_scp_dict = {}
    for line in open(test_scp_file):
        fields = line.strip().split()
        wav_id = fields[0]
        wav_path = fields[1]
        wav_scp_dict[wav_id] = wav_path
    return wav_scp_dict


def get_word_score_dict(word_score_dict_file):
    word_score_dict = pickle.load(open(word_score_dict_file))
    return word_score_dict


def select_instance(occurance_dict, keywords_score_low, keywords_score_high, select_num):
    for keyword in occurance_dict.keys():
        
    
if __name__=="__main__":
    if len(sys.argv) < 7:
        print("UDAGE: python "+ sys.argv[0]+ " keyowrds.list test_scp word_score_dict.pkl cmt_file keywords_score_low keywords_score_high num")
        exit(1)
    
    keywords_list = build_keywords_list(sys.argv[1])
    
    test_scp_dict = build_wav_scp_dict(sys.argv[2])

    word_score_dict = get_word_score_dict(sys.argv[3]) 
    
    build_occurance_dict(word_score_dict, keywords_list, test_scp_dict.keys())

    cmt_occurance_dict = build_ctm_occorrance_dict(sys.argv[4], keywords_list, test_scp_dict.keys())

    keywords_score_low=float(sys.argv[4])
    keywords_score_high=float(sys.argv[5])
    select_num = int(sys.argv[6]
    
