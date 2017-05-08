#!/bin/bash

echo "$0 $@"
echo ""

. ./path.sh
if [ $# != 3 ]; then
    echo "Udage: $0 <listfile> <log dir> <job number>"
    exit 1;
fi

listfile=$1
log_dir=$2
jb_num=$3
   
tmp_list_dir=`mktemp -d temp.XXXX`
mkdir -p ${log_dir}

python local/split.py $listfile $tmp_list_dir/ $jb_num 

list_file_base_name=`basename $listfile`

run.pl JOB=1:$jb_num $log_dir/convert_amr2wav.JOB.log \
  local/ffmpeg_call.sh ${tmp_list_dir}/${list_file_base_name}JOB amr wav

rm -r $tmp_list_dir
