import sys
import log
import base

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
    if len(sys.argv) < 2:
        print("UDAGE: python "+ sys.argv[0]+ " keywords_list_file")
        exit(1)

    instance_list1 = base.build_list(sys.argv[1])
    keyword_num_dict1 = build_keyword_num_dict(instance_list1)
#    instance_list2 = base.build_list(sys.argv[2])
#    keyword_num_dict2 = build_keyword_num_dict(instance_list2)

    for word_id in keyword_num_dict1.keys():
        print("%s %d"%(word_id,len(keyword_num_dict1[word_id])))

    
