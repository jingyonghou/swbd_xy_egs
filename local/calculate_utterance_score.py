import sys
import numpy as np
import log
import pickle

if __name__=="__main__":
    if len(sys.argv) < 3:
        print("UDAGE: python "+ sys.argv[0]+ " score_dict.pkl sentence_score.list")
        exit(1)
    score_dict_fid = open(sys.argv[1], "rb")
    score_dict=pickle.load(score_dict_fid)
    fid = open(sys.argv[2], "w")
    for sentence_id in score_dict.keys():
        n = len(score_dict[sentence_id])
        score = 0;
        for i in range(n):
            score += score_dict[sentence_id][i][3]
        score /= n
        fid.writelines("%s\t%f\n"%(sentence_id, score))
    fid.close()

