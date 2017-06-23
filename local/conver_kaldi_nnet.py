import sys
import log


if __name__=="__main__":
    if len(sys.argv) < 3:
        print("UDAGE: python "+ sys.argv[0]+ "source_nnet_file(txt format) target_nnet_file(txt format)\n ")
        exit(1)

    fid = open(sys.argv[2], "w")
    for line in open(sys.argv[1]).readlines():
        first_token = line.strip().split()[0]
        if first_token == "<Nnet>":
            fid.writelines(line.strip())
            fid.writelines("\n")
            continue
        elif first_token == "</Nnet>":
            fid.writelines(line)
            log.Log("finish transfer the net")
            break;
        elif first_token == "<!EndOfComponent>":
            continue
        elif first_token == "<LearnRateCoef>":
        #find [ and ], then write the data between them
            start = line.find("[")
            end = line.find("]") 
            if end == -1:
                continue
            elif end != -1 and start != -1 and end > start:
                fid.writelines(line[start+1:end].strip())
                fid.writelines("\n")
            else:
                log.Error("Wrong line %s"%line)
        elif first_token == "[":
        # remove the [ and write rest of the line
            start = line.find("[") 
            end = line.find("]")
            if end == -1:
                continue
            elif end > start:
                fid.writelines(line[start+1:end].strip())
                fid.writelines("\n")
            else:
                log.Error("Wrong line %s"%line)
        elif first_token[0] == "<":
        # write this line
            fid.writelines(line.strip())
            fid.writelines("\n")
            continue
        else:
            end = line.find("]")
            if end != -1:
                line=line[:end]
            fid.writelines(line.strip())
            fid.writelines("\n")
            continue
            
    fid.close()

        

