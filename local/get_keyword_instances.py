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
    for line in open(wav_scp_file).readlines():
        fields = line.strip().split()
        wav_id = fields[0]
        wav_path = fields[1]
        wav_scp_dict[wav_id] = wav_path
    return wav_scp_dict


def get_word_score_dict(word_score_dict_file):
    word_score_dict = pickle.load(open(word_score_dict_file))
    return word_score_dict

def build_occurance_dict(word_score_dict, keywords_list, test_scp_list):
    occurance_dict = {}
    for keyword in keywords_list:
        occurance_dict[keyword] = []

    for wav_id in test_scp_list:
        if wav_id in word_score_dict.keys():
            word_score_list = word_score_dict[wav_id]
        else:
            continue
        # check unigram word
        for i in range(len(word_score_list)):
            word = word_score_list[i][2].lower()
            if not word in keywords_list:
                continue
            start_frame = float(word_score_list[i][0])
            end_frame = float(word_score_list[i][1])
            score = float(word_score_list[i][3])
            occurance_dict[word].append([wav_id, start_frame, end_frame, score])
        for i in range(len(word_score_list)-1):
            word1 = word_score_list[i][2].lower()
            word2 = word_score_list[i+1][2].lower()
            phrase = word1 + "-" + word2
            if not phrase in keywords_list:
                continue
            start_frame1 = float(word_score_list[i][0])
            end_frame1 = float(word_score_list[i][1])
            score1 = float(word_score_list[i][3])
            start_frame2 = float(word_score_list[i+1][0])
            end_frame2 = float(word_score_list[i+1][1])
            score2 = float(word_score_list[i+1][3])
            score = 0.5 * (score1+score2)
            occurance_dict[phrase].append([wav_id, start_frame1, end_frame1, start_frame2, end_frame2, score])
    return occurance_dict

def build_ctm_occorrance_dict(ctm_file, word_score_dict, keywords_list, test_scp_list):
    return {}

def select_instance(occurance_dict, keywords_score_low, keywords_score_high, select_num):
    selected_instance_dict = {}
    for keyword in occurance_dict.keys():
        instance_candidates = []
        for instance in occurance_dict[keyword]:
            if instance[-1] >= keywords_score_low and instance[-1] <= keywords_score_high:
                instance_candidates.append(instance)
        if len(instance_candidates) < select_num:
            selected_instance_dict[keyword] = random.sample(instance_candidates, len(instance_candidates))
        else:
            selected_instance_dict[keyword] = random.sample(instance_candidates, select_num)
    return selected_instance_dict

def frame2point(frame_list, sample_rate=SAMPLERATE):
    point_list = []
    for frame in frame_list:
        point_list.append(int(frame * SAMPLERATE / 100))        
    return point_list

def write_instance(selected_instance_dict, test_scp_dict, out_dir):
    for keyword in selected_instance_dict:
        for i in range(len(selected_instance_dict[keyword])):
            keyword_name = "-".join(keyword.split())
            instance_file_name = out_dir + keyword_name + "_" + str(i) + ".wav"
            wav_id = selected_instance_dict[keyword][i][0]
            frame_range = selected_instance_dict[keyword][i][1:-1]
            point_range = frame2point(frame_range)

            source_file = test_scp_dict[wav_id]
            source_data = wavedata.readwave(source_file)
            if len(point_range) == 2:
                target_data = source_data[point_range[0]:point_range[1]+DELAY]
            elif len(point_range) == 4:
                if point_range[2] - point_range[1] > DELAY:
                    target_data1 = source_data[point_range[0]:point_range[1]+DELAY]
                else:
                    target_data1 = source_data[point_range[0]:point_range[1]]
                target_data2 = source_data[point_range[2]:point_range[3]+DELAY]
                target_data = np.concatenate([target_data1, target_data2])
            else:
                log.Error("Wrong number of instance range")

            wavedata.writewave(instance_file_name, target_data, 1, 2, 8000)

if __name__=="__main__":
    if len(sys.argv) < 8:
        print("UDAGE: python "+ sys.argv[0]+ " keyowrds.list test_scp word_score_dict.pkl cmt_file keywords_score_low keywords_score_high num out_dir")
        exit(1)
    
    keywords_list = build_keywords_list(sys.argv[1])
    
    test_scp_dict = build_wav_scp_dict(sys.argv[2])

    word_score_dict = get_word_score_dict(sys.argv[3]) 
    
    occurance_dict = build_occurance_dict(word_score_dict, keywords_list, test_scp_dict.keys())

    cmt_occurance_dict = build_ctm_occorrance_dict(sys.argv[4], word_score_dict,  keywords_list, test_scp_dict.keys())

    keywords_score_low=float(sys.argv[4])
    keywords_score_high=float(sys.argv[5])
    select_num = int(sys.argv[6])
    out_dir = sys.argv[7]

    selected_instance_dict = select_instance(occurance_dict, keywords_score_low, keywords_score_high, select_num)
    write_instance(selected_instance_dict, test_scp_dict, out_dir)
