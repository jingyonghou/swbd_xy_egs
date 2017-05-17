import sys
import log
import calculate_occurance_of_keywords as cok

if __name__=="__main__":
    if len(sys.argv) < 4:
        print("UDAGE: python "+ sys.argv[0]+ " keywords_list_file text search_data_scp keyword_occurance_dict sentence_summery_file")
        exit(1)
    keywords_list = cok.build_keywords_list(sys.argv[1])
    occurance_dict = cok.build_occurance_dict(keywords_list, sys.argv[2])
    keyword_dict = {}
    for word in keywords_list:
        keyword_dict[word] = 0;

    keyword_occurance_fid = open(sys.argv[4], "w")
    sentence_summery_fid = open(sys.argv[5], "w")

    for line in open(sys.argv[3]).readlines():
        fields = line.strip().split()
        wav_id = fields[0]
        text_id = "_".join(wav_id.split("_")[0:2])
        text = " ".join(fields[1:])
        containing_keywords = occurance_dict[text_id] 
        sentence_summery_fid.writelines("%s\t"%wav_id)
        for keyword in occurance_dict[text_id]:
            keyword_dict[keyword] += 1
            sentence_summery_fid.writelines("\'%s\' "%keyword)
        sentence_summery_fid.writelines("\t%s\n"%text)
    for word in keywords_list:
        keyword_occurance_fid.writelines("%s\t%d\n"%(word, keyword_dict[word]))

    keyword_occurance_fid.close()
    sentence_summery_fid.close()
