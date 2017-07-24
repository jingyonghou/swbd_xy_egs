import sys
import os
import shutil

def get_file_list(list_file):
    file_list=[]
    for x in open(list_file).readlines():
        file_list.append(x.strip())
    return file_list

def mkdir(path):
    is_exists = os.path.exists(path)
    if not is_exists:
        os.makedirs(path)

def copy_file(source_data, target_data):
    path = os.path.dirname(target_data)
    mkdir(path)
    is_source_exists = os.path.exists(source_data)
    if not is_source_exists:
        print("source file is not exist: %s"%source_data)
    else:
        shutil.copyfile(source_data, target_data)
        
if __name__=="__main__":
    if(len(sys.argv)<3):
        print("UDAGE: python "+ sys.argv[0]+ " file_list_file source_data_dir target_data_dir sufix")
        exit(1)
    file_list = get_file_list(sys.argv[1])
    source_data_dir = sys.argv[2]
    target_data_dir = sys.argv[3]
    data_type = sys.argv[4]
    #convert spx file to amr (amr file is empty and spx is not)
    for x in file_list:
        source_data = source_data_dir + "/" + x + "." + data_type
        target_data = target_data_dir + "/" + x + "." + data_type
        
        copy_file(source_data, target_data)
        
        
