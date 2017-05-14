import sys
import random

def suffle_list(list_file):
    suffled_list=[]
    for x in open(list_file).readlines():
        suffled_list.append(x.strip())
    random.shuffle(suffled_list)
    return suffled_list

if __name__=="__main__":
    if(len(sys.argv) < 3):
        print("USAGE: python " + sys.argv[0] + " source_list target_list")
        exit(1)
    suffled_list = suffle_list(sys.argv[1])
    fid = open(sys.argv[2], "w")
    for x in suffled_list:
        fid.writelines(x+"\n")
    fid.close()
