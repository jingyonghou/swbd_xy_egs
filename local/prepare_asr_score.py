import sys
import base
def relevant(query, text_id, occurance_dict):
    if query in occurance_dict[text_id]:
        return True
    return False

def build_occurance_dict(keywords_list, text_file):
    keywords_list_uniq = set()
    for keyword in keywords_list:
        keywords_list_uniq.add(keyword.strip().split("_")[0])
    occurance_dict = {}
    for line in open(text_file).readlines():
        fields = line.strip().split()
        text_id = fields[0]
        single_words = fields[1:]
        occurance_dict[text_id] = set()
        for i in range(len(single_words)):
            if single_words[i] in keywords_list_uniq:
                occurance_dict[text_id].add(single_words[i])

        for i in range(len(single_words)-1):
            word1 = single_words[i]
            word2 = single_words[i+1]
            phrase = word1 + "-" + word2
            if phrase in keywords_list_uniq:
                occurance_dict[text_id].add(phrase)
    return occurance_dict

if __name__=="__main__":
    if len(sys.argv) < 4:
        print("UDAGE: python "+ sys.argv[0]+ " keyword_list_file utter_asr_out result_dir")
        exit(1)
    keywords_list = base.build_list(sys.argv[1])
    utterances_list = base.build_list(sys.argv[2])
    occurance_dict = build_occurance_dict(keywords_list, sys.argv[2])

    result_dir = sys.argv[3] 

    for keyword in keywords_list:
        fid = open(result_dir + "/" + keyword + ".RESULT","w")
        for utter_id in utterances_list:
            if relevant(keyword, utter_id, occurance_dict):
                fid.writelines("%f\n"%0)
            else:
                fid.writelines("%f\n"%1)
        fid.close()
