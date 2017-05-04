import sys
import log
import numpy as np
import wavedata
import random

DELAY=320
SAMPLERATE=8000
def build_word_ctm_dict(ctm_file, keywords):
    ctm_dict={}
    sentence_dict={}
    for line in open(ctm_file).readlines():
        fields = line.strip().split()
        text_id = fields[0]
        start_time = float(fields[2])
        duration = float(fields[3])
        word = fields[4]
        if not sentence_dict.has_key(text_id):
            sentence_dict[text_id] = []
        sentence_dict[text_id].append([start_time, duration, word])

    # build unigram words
    for text_id in sentence_dict.keys():
        for i in range(len(sentence_dict[text_id])):
            start_time, duration, word = sentence_dict[text_id][i]
            if word in keywords:
                if not ctm_dict.has_key(word):
                    ctm_dict[word] = []
                ctm_dict[word].append([text_id, start_time, duration])

    # build bigram words
    for text_id in sentence_dict.keys():
        for i in range(len(sentence_dict[text_id])-1):
            start_time1, duration1, word1 = sentence_dict[text_id][i]
            start_time2, duration2, word2 = sentence_dict[text_id][i+1]
            phrase = word1 + " " + word2
            if phrase in keywords:
                if not ctm_dict.has_key(phrase):
                    ctm_dict[phrase] = []
                if start_time2-start_time1-duration1 >= 0.2:
                    log.Warn("too big interval %f s (%f) between the two word of the phrase %s in sentence %s"%(start_time2-start_time1-duration1, start_time2-start_time1+duration2, phrase, text_id))
                    continue
                ctm_dict[phrase].append([text_id, start_time1, start_time2-start_time1+duration2])
    return ctm_dict

def build_native_wav_dict(wav_scp_file):
    wav_scp_dict={}
    for line in open(wav_scp_file).readlines():
        fields = line.strip().split()
        text_id = fields[0]
        wav_path = fields[1]
        if wav_scp_dict.has_key(text_id):
            log.Error("duplicated native wav for text id: %d"%text_id)

        wav_scp_dict[text_id]=wav_path
    return wav_scp_dict

def get_keyword_list(keyword_file):
    keywords=[]
    for line in open(keyword_file).readlines():
        keywords.append(line.strip())
    return keywords

def time2point(seconds, sample_rate=SAMPLERATE):
    return int(seconds * sample_rate)

def write_instance(keywords, ctm_dict, wav_scp_dict,  max_num, keyword_dir):
    for keyword in keywords:
        instances = ctm_dict[keyword]
        extract_num = min(len(instances), max_num)
        extract_instances = random.sample(instances, extract_num)
        for i in range(extract_num):
            instance_id = keyword + "_" +str(i)
            sourcefile = wav_scp_dict[extract_instances[i][0]]
            start_point = time2point(extract_instances[i][1])
            duration = time2point(extract_instances[i][2])

            sourcedata = wavedata.readwave(sourcefile)
            if not start_point >= 0 or not start_point+duration<len(sourcedata):
                log.Error("wrong extract position of sentance %s: start point: %d, end point: %d"%(text_id, start_point, start_point+duration))
            targetdata = sourcedata[start_point:start_point+duration+DELAY]
            wavedata.writewave(keyword_dir + instance_id+".wav", targetdata, 1, 2, 8000) 
    
    
if __name__=="__main__":
    if len(sys.argv) < 6:
        print("UDAGE: python "+ sys.argv[0]+ "keywordslist ctmfile native_wav_scp_file max_num output_dir")
        exit(1)
    keywords = get_keyword_list(sys.argv[1]) 
    ctm_dict = build_word_ctm_dict(sys.argv[2], keywords)
    native_wav_scp_dict = build_native_wav_dict(sys.argv[3])
    max_num = int(sys.argv[4])
    output_dir = sys.argv[5]
    write_instance(keywords, ctm_dict, native_wav_scp_dict, max_num, output_dir)

