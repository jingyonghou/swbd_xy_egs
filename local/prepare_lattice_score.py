import sys
import base
import numpy as np
def build_result_dict(result_file_name):
    result_dict={}
    for line in open(result_file_name).readlines():
        fields = line.strip().split()
        keyword_id = fields[0]
        utter_id = int(fields[1])
        start_frame = fields[2]
        end_frame = fields[3]
        score = 1-np.exp(-float(fields[4]))
        if not result_dict.has_key(keyword_id):
            result_dict[keyword_id] = {}
        if not result_dict[keyword_id].has_key(utter_id):
            result_dict[keyword_id][utter_id] = score
        else:
            pre_score = result_dict[keyword_id][utter_id]
            result_dict[keyword_id][utter_id] = min(score, pre_score)
    return result_dict
     
if __name__=="__main__":
    if len(sys.argv) < 5:
        print("UDAGE: python "+ sys.argv[0]+ " src_result keyword_list_file utter_id_file result_dir")
        exit(1)
    
    result_dict = build_result_dict(sys.argv[1])
    keywords_list = base.build_list(sys.argv[2])
    utter_id_dict = base.build_scp_dict_reverse(sys.argv[3])
    result_dir = sys.argv[4]
    for keyword in keywords_list:
        fid = open(result_dir + "/" + keyword + ".RESULT","w")
        if result_dict.has_key(keyword):
            for i in range(1,len(utter_id_dict)+1):
                if result_dict[keyword].has_key(i):
                    fid.writelines("%f\n"%result_dict[keyword][i])
                else:
                    fid.writelines("%f\n"%1.1)
        else:
            for i in range(1,len(utter_id_dict)+1):
                fid.writelines("%f\n"%1.1)
        fid.close()
