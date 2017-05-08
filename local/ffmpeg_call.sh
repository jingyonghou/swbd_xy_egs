#!/bin/bash

echo "$0 $@"
echo ""

if [ $# != 3 ]; then
    echo "Udage: $0 <listfile> <source type> <target type>"
    exit 1;

fi

listfile=$1
source_type=$2
target_type=$3

for filename in `cat $listfile`; 
do
  echo "ffmpeg -i ${filename}.${source_type} -y -r ${filename}.${target_type}"
  ffmpeg -i ${filename}.${source_type} -ac 1 -ar 8000 -y ${filename}.${target_type}
done
