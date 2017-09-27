import sys

def get_isolate_set(keyword_list):
    isolate_set = set();
    for line in keyword_list:
        words = line.strip().split("-")
        for word in words:
            isolate_set.add(word)
    return isolate_set

if __name__=="__main__":
    if len(sys.argv) < 3:
        print("USAGE: python %s keywords.list isolate.list")
        exit(1)
    
    keyword_list = open(sys.argv[1]).readlines()
    isolate_set = get_isolate_set(keyword_list)

    fid = open(sys.argv[2], "w")
    for word in isolate_set:
        fid.writelines(word)
        fid.writelines("\n")
    fid.close();
        
