import sys

def build_text_id_list(text_id_list_file):
    text_id_list = []
    for x in open(text_id_list_file).readlines():
        text_id_list.append(x.strip().split()[0])
    return text_id_list

if __name__=="__main__":
    if(len(sys.argv) < 4):
        print("USAGE: python " + sys.argv[0] + "text_id_list source_dir target_dir")
        exit(1)
    text_id_list = build_text_id_list(sys.argv[1])
    source_dir = sys.argv[2]
    target_dir = sys.argv[3]
    for x in ["wav.scp", "text", "utt2spk"]:
        source_file = source_dir + x
        target_file = target_dir + x
        fid = open(target_file, "w")
        for line in open(source_file).readlines():
            fields = line.strip().split()
            wav_id = fields[0]
            text_id = "_".join(wav_id.split("_")[0:2])
            if text_id in text_id_list:
                fid.writelines(line)
        fid.close()
