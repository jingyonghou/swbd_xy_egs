import sys

text_file = sys.argv[1]
text_raw_file = sys.argv[2]

fid = open(text_raw_file, "w")
for line in open(text_file).readlines():
    fields = line.strip().split()
    fid.writelines(" ".join(fields[1:]))
    fid.writelines("\n")    
fid.close()
