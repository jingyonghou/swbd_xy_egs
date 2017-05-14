import sys
import log

if __name__=="__main__":
    if(len(sys.argv) < 3):
        print("USAGE: python " + sys.argv[0] + " wav.scp speaker_id.list")
    speaker_id_set = set()
    for x in open(sys.argv[1]).readlines():
        wav_id = x.strip().split()[0]
        speaker_id = wav_id.split("_")[1]
        speaker_id_set.add(speaker_id)
    
    fid = open(sys.argv[2], "w")
    for x in speaker_id_set:
        fid.writelines(x+"\n")
    fid.close()
