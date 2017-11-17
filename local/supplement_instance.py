import sys
import base
import random

def build_keyword_num_dict(instance_list):
    keyword_num_dict = {}
    for instance_id in instance_list:
        fields = instance_id.strip().split("_")
        keyword_id = fields[0]
        if not keyword_num_dict.has_key(keyword_id):
            keyword_num_dict[keyword_id] = []
        keyword_num_dict[keyword_id].append(instance_id)
    return keyword_num_dict

if __name__=="__main__":
    if len(sys.argv) < 5:
        print("USAGE: python %s keywords_scp1 keywords_scp2 num copy_list"%(sys.argv[0]))
        exit(1)

    instance_list1 = base.build_list(sys.argv[1])
    keyword_num_dict1 = build_keyword_num_dict(instance_list1)
    
    instance_list2 = base.build_list(sys.argv[2])
    keyword_num_dict2 = build_keyword_num_dict(instance_list2)
    
    scp_dict = base.build_scp_dict(sys.argv[2])
   
    num = int(sys.argv[3])
    fid = open(sys.argv[4],"w") 
    copy_list = []
    for keyword_id in keyword_num_dict1.keys():
        select_num = num - len(keyword_num_dict1[keyword_id])
        if(len(keyword_num_dict2[keyword_id]) < select_num):
            select_num = len(keyword_num_dict2[keyword_id])
        copy_list = random.sample(keyword_num_dict2[keyword_id], select_num)
        # copy file   
        for instance_id in copy_list:
            fid.writelines("%s\n"%(instance_id.strip()))
    fid.close()


