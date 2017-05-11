import sys
import log

def build_keywords_list(keywords_list_file):
    keywords_list = []
    for line in open(keywords_list_file).readlines():
        keywords_list.append(line.strip())
    return keywords_list

def build_occurance_dict(keywords_list, text_file):
    occurance_dict = {}
    for line in open(text_file).readlines():
        fields = line.strip().split()
        text_id = fields[0]
        single_words = fields[1:]
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

if __name__=="__main__":
    if len(sys.argv) < 4:
        print("UDAGE: python "+ sys.argv[0]+ " keywords_list_file text summery_file")
        exit(1)
    keywords_list = build_keywords_list(sys.argv[1])
    occurance_dict = build_occurance_dict(keywords_list, sys.argv[2])
    fid = open(sys.argv[3], "w")
    for text_id in occurance_dict.keys():
        fid.writelines("%s\t%d:"%(text_id, len(occurance_dict[text_id])))
        for keyword in occurance_dict[text_id]:
            fid.writelines("\"%s\" "%keyword)
        fid.writelines("\n")
    fid.writelines("\n\nsummer of the occurance\n")

    # calculate the the number
    occurance_num = 0
    for text_id in occurance_dict.keys():
        occurance_num += len(occurance_dict[text_id])    
    fid.writelines("total occurance: %d "%occurance_num)
    fid.close() 
