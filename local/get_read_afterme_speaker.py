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

if __name__=="__main__":
    if(len(sys.argv) < 4):
        print("USAGE: python " + sys.argv[0] + " jsonfile.list wav.scp speaker_id.list")
        exit(1)
    speaker_dict = build_speaker_dict(sys.argv[1])
    speaker_id_set = set()
    for x in open(sys.argv[2]).readlines():
        wav_id = x.strip().split()[0]
        audio_id = wav_id.split("_")[2]
        if not speaker_dict.has_key(audio_id):
            log.Warn("no json record for the audio: %s"%wav_id)
            continue
        speaker_id = speaker_dict[audio_id]
        speaker_id_set.add(speaker_id)
    fid = open(sys.argv[3], "w")
    for x in speaker_id_set:
        fid.writelines(x+"\n")
    fid.close()
