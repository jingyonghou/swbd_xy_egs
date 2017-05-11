import sys
import log
import get_search_dataset as GSD
from XiaoYingWave import XiaoYingWave

def get_keyword_score_list(keyowrds_list, word_score_list):
    keyword_score_list = []
    n_words = len(word_score_list)
    for i in range(n_words):
        word = word_score_list[i][2].lower()
        score = float(word_score_list[i][3])
        if word in keywords_list:
            keyword_score_list.append(score)
    # bigram word
    for i in range(n_words-1):
        word1 = word_score_list[i][2].lower()
        word2 = word_score_list[i+1][2].lower()
        phrase = word1 + " " + word2
        score1 = float(word_score_list[i][3])
        score2 = float(word_score_list[i+1][3])
        score =0.5 * (score1+score2)
        if phrase in keywords_list:
            keyword_score_list.append(score) 
    return keyword_score_list

if __name__=="__main__":
    if len(sys.argv) < 8:
        print("UDAGE: python "+ sys.argv[0]+ " word_score_dict.pkl keyowrds.list test_scp test_text score_low score_high keyword_score.txt")
        exit(1)
    word_score_file = sys.argv[1]
    keyword_list_file = sys.argv[2]
    test_scp_file = sys.argv[3]
    search_text_file = sys.argv[4]
    score_low = float(sys.argv[5])
    score_high = float(sys.argv[6])
    keyword_score_file = sys.argv[7]
    
    fid = open(keyword_score_file, "w")
    keywords_list = GSD.build_keywords_list(keyword_list_file)
    test_scp_dict = GSD.build_test_scp_dict(test_scp_file)
    text_dict = GSD.build_text_dict(search_text_file)
    test_wave_entities = {}
    for text_id in text_dict.keys():
        test_wave_entities[text_id]=XiaoYingWave(text_id, text_dict[text_id])

    word_score_dict = GSD.get_word_score_dict(word_score_file)
    for wav_id in test_scp_dict.keys():
        text_id = "_".join(wav_id.split("_")[0:2])
        word_score_list = word_score_dict[wav_id]
        sentence_score = GSD.get_sentence_score(word_score_list)
        test_wave_entities[text_id].setWavList(wav_id, sentence_score)
    # select_wav
    keyword_score_list_all = []
    for text_id in test_wave_entities.keys():
        selected_wav_list = test_wave_entities[text_id].getWav(score_low, score_high)
        for i in range(len(selected_wav_list)):
            wav_id = selected_wav_list[i]
            keyword_score_list_all += get_keyword_score_list(keywords_list, word_score_dict[wav_id])

    for score in keyword_score_list_all:
        fid.writelines("%f\n"%score)
    fid.close()

