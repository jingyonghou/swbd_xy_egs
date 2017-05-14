import sys
import log
import json

def get_speaker_set(speaker_list_file):
    speaker_set=set()
    for x in open(speaker_list_file).readlines():
        speaker_set.add(x.strip())
    return speaker_set

if __name__=="__main__":
    if(len(sys.argv) < 4):
        print("USAGE: python " + sys.argv[0] + "  exclude_speaker.list source_wav.scp target_wav.scp")
        exit(1)
    exclude_speaker_set = get_speaker_set(sys.argv[1])
    fid = open(sys.argv[3], "w")
    
    for x in open(sys.argv[2]).readlines():
        wav_id = x.strip().split()[0]
        audio_id = wav_id.split("_")[2]
        speaker_id = wav_id.split("_")[1]
        if not speaker_id in exclude_speaker_set:
            fid.writelines(x)
    fid.close()

