import log
import sys

def get_id_list(file_name):
    id_list = []
    for x in open(file_name).readlines():
        id_list.append(x.strip().split()[0])
    return id_list

if __name__=="__main__":
    if(len(sys.argv) < 4):
        print("USAGE: python " + sys.argv[0] + "exclude_list source_list target_list")
        exit(1)
    exclude_list = get_id_list(sys.argv[1])

    fid = open(sys.argv[3], "w")
    exclude_num = 0
    for line in open(sys.argv[2]).readlines():
        wav_id = line.strip().split()[0]
        if not wav_id in exclude_list:
            fid.writelines(line)
            continue
        exclude_num += 1
    fid.close()
    log.Log("excluded number: %d  vs total: %d"%(exclude_num, len(exclude_list))) 
