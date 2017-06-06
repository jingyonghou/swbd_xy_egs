import sys
import log
import pickle

def build_sentence_score_dict(word_score_dict_file):
    sentence_score_dict = {}

    word_score_dict_fid = open(sys.argv[1], "rb")
    word_score_dict=pickle.load(word_score_dict_fid)
    for sentence_id in word_score_dict.keys():
        n = len(word_score_dict[sentence_id])
        score = 0;
        for i in range(n):
            score += float(word_score_dict[sentence_id][i][3])
        score /= n
        if sentence_score_dict.has_key(sentence_id):
            log.Error("repeated sentence id:%s"%sentence_id)
        sentence_score_dict[sentence_id] = score
    return sentence_score_dict

def select_utterance_by_score(source_wav_scp, low_score, high_score):
    target_wav_scp_list = []
    for line in open(source_wav_scp).readlines():
        fields = line.strip().split()
        sentence_id = fields[0]
        path = fields[1]
        if not sentence_score_dict.has_key(sentence_id):
            log.Warn("no score file for this sentence id: %s"%(sentence_id))
            continue
        if sentence_score_dict[sentence_id] > low_score and sentence_score_dict[sentence_id] <= high_score:
            target_wav_scp_list.append(line)
    return target_wav_scp_list

if __name__=="__main__":
    if len(sys.argv) < 6:
        print("UDAGE: python "+ sys.argv[0]+ " score_dict.pkl source_wav_scp lowscore highscore target_wav_scp ")
        exit(1)
    sentence_score_dict = build_sentence_score_dict(sys.argv[1])
    source_wav_scp = sys.argv[2]
    low_score = float(sys.argv[3])
    high_score = float(sys.argv[4])
    fid = open(sys.argv[5], "w") # target_wav_scp
    target_wav_scp_list = select_utterance_by_score(source_wav_scp, low_score, high_score)

    for line in target_wav_scp_list:
        fid.writelines(line)
    fid.close()

