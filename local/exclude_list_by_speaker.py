import sys
import log
import json
def build_speaker_dict(jsonlistfile):
    speaker_dict = {}
    json_list = open(jsonlistfile).readlines()
    for line in json_list:
        json_items = open(line.strip()).readlines()
        for json_item in json_items:
            json_entity = json.loads(json_item.strip())
            if json_entity.has_key("AudioName"):
                audio_id = str(json_entity["AudioName"])
            elif json_entity.has_key("audioName"):
                audio_id = str(json_entity["audioName"])
            else:
                log.Error("bad json file:%s"%json_item)

            if json_entity.has_key("UserId"):
                user_id_entity = json_entity["UserId"]
                if user_id_entity.has_key("Id"):
                    user_id = user_id_entity["Id"]
                elif user_id_entity.has_key("id"):
                    user_id = user_id_entity["id"]
                else:
                    log.Error("bad json file:%s"%json_item)
            elif json_entity.has_key("userId"):
                user_id_entity = json_entity["userId"]
                if user_id_entity.has_key("Id"):
                    user_id = user_id_entity["Id"]
                elif user_id_entity.has_key("id"):
                    user_id = user_id_entity["id"]
                else:
                    log.Error("bad json file:%s"%json_item)
            else:
                log.Error("bad json file:%s"%json_item)

            
            speaker_dict[audio_id]=user_id
    return speaker_dict

def get_speaker_set(speaker_list_file):
    speaker_set=set()
    for x in open(speaker_list_file).readlines():
        speaker_set.add(x.strip())
    return speaker_set

if __name__=="__main__":
    if(len(sys.argv) < 5):
        print("USAGE: python " + sys.argv[0] + " jsonfile.list source_wav.scp exclude_speaker.list target_wav.scp")
        exit(1)
    speaker_dict = build_speaker_dict(sys.argv[1])
    exclude_speaker_set = get_speaker_set(sys.argv[2])
    fid = open(sys.argv[4], "w")
    
    for x in open(sys.argv[3]).readlines():
        wav_id = x.strip().split()[0]
        audio_id = wav_id.split("_")[2]
        speaker_id = speaker_dict[audio_id]
        if not speaker_id in exclude_speaker_set:
            fid.writelines(x)
    fid.close()

