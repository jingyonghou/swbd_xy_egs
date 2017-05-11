import sys
import log
import pickle
from XiaoYingWave import XiaoYingWave

def build_keywords_list(keywords_list_file):
    keywords_list = []
    for line in open(keywords_list_file, "rb").readlines():
        keywords_list.append(line.strip())
    return keywords_list

def build_text_dict(text_file):
    text_dict = {}
    for line in open(text_file).readlines():
        fields = line.strip().split()
        text_id = fields[0]
        text = " ".join(fields[1:])
        text_dict[text_id] = text
    return text_dict

def build_test_scp_dict(test_scp_file):
    test_scp_dict = {}
    for line in open(test_scp_file):
        fields = line.strip().split()
        wav_id = fields[0]
        wav_path = fields[1]
        test_scp_dict[wav_id] = wav_path
    return test_scp_dict

def get_word_score_dict(word_score_dict_file):
    word_score_dict = pickle.load(open(word_score_dict_file))
    return word_score_dict

def build_occurance_dict(keywords_list, text_dict):
    occurance_dict = {}
    for text_id in text_dict.keys():
        single_words = text_dict[text_id].strip().split()
        occurance_dict[text_id] = []
        for i in range(len(single_words)):
            if single_words[i] in keywords_list:
                occurance_dict[text_id].append(single_words[i])

        for i in range(len(single_words)-1):
            word1 = single_words[i]
            word2 = single_words[i+1]
            phrase = word1 + " " + word2
            if phrase in keywords_list:
                occurance_dict[text_id].append(phrase)
    return occurance_dict

def get_sentence_score(word_score_list):
    n = len(word_score_list)
    score = 0
    for i in range(n):
        score += word_score_list[i][3]
    score /= n
    return score

def is_candidate(occurance_list, word_score_list, keywords_score_low, keywords_score_high):
    MAX_INTERVAL = 20
    if len(occurance_list) <= 0:
        return True
    min_keyword_score = 100
    max_keyword_score = 0
    n_occur = len(occurance_list)
    n_words = len(word_score_list)
    # unigram word
    for i in range(n_words):
        word = word_score_list[i][2].lower()
        score = float(word_score_list[i][3])
        if word in occurance_list:
            if score > max_keyword_score:
                max_keyword_score = score
            if score < min_keyword_score:
                min_keyword_score = score
    # bigram word
    max_interval = 0
    for i in range(n_words-1):
        word1 = word_score_list[i][2].lower()
        word2 = word_score_list[i+1][2].lower()
        phrase = word1 + " " + word2
        score1 = float(word_score_list[i][3])
        score2 = float(word_score_list[i+1][3])
        score =0.5 * (score1+score2)
        interval = float(word_score_list[i+1][0]) - float(word_score_list[i][1])
        if phrase in occurance_list:
            if score > max_keyword_score:
                max_keyword_score = score
            if score < min_keyword_score:
                min_keyword_score = score
            if interval > max_interval:
                max_interval = interval
    if max_interval <= MAX_INTERVAL and min_keyword_score >= keywords_score_low and max_keyword_score <= keywords_score_high:
        return True
    return False

def select_wav(wav_dict, score_low, score_high, num, uttscpfid):
    for text_id in wav_dict.keys():
        selected_wav_list = wav_dict[text_id].getWav(score_low, score_high, num)
        for i in range(len(selected_wav_list)):
            uttscpfid.writelines(selected_wav_list[i] + "\n")

if __name__=="__main__":
    if len(sys.argv) < 11:
        print("UDAGE: python "+ sys.argv[0]+ " word_score_dict.pkl keyowrds.list test_scp test_text score_low score_high keywords_score_low keywords_score_high num wav_scp_file")
        exit(1)
    word_score_file = sys.argv[1]
    keyword_list_file = sys.argv[2]
    test_scp_file = sys.argv[3]
    search_text_file = sys.argv[4]
    score_low = float(sys.argv[5])
    score_high = float(sys.argv[6])
    keywords_score_low = float(sys.argv[7])
    keywords_score_high = float(sys.argv[8])
    select_num = int(sys.argv[9])
    wav_scp_file = sys.argv[10]
    
    word_score_dict = get_word_score_dict(word_score_file)
    keywords_list = build_keywords_list(keyword_list_file)
    test_scp_dict = build_test_scp_dict(test_scp_file)
    text_dict = build_text_dict(search_text_file)
    occurance_dict = build_occurance_dict(keywords_list, text_dict)
    
    fid = open(wav_scp_file, "w")
    
    test_wave_entities = {}
    for text_id in text_dict.keys():
        test_wave_entities[text_id]=XiaoYingWave(text_id, text_dict[text_id])

    for wav_id in test_scp_dict.keys():
        text_id = "_".join(wav_id.split("_")[0:2])
        word_score_list = word_score_dict[wav_id]
        if is_candidate(occurance_dict[text_id], word_score_list, keywords_score_low, keywords_score_high):
            sentence_score = get_sentence_score(word_score_list)
            test_wave_entities[text_id].setWavList(wav_id, sentence_score)
    select_wav(test_wave_entities, score_low, score_high, select_num, fid)
    fid.close()
