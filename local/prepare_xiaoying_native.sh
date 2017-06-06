#!/bin/bash

#get native text sentence and audio list\

. ./path.sh

echo "$0 $@"

if [ $# -gt 1 ]; then
  echo "Usage: prepare_xiaoying_native.sh /path/to/xiaoyingnative"
  exit 1;
fi

export LC_ALL=C;
xiaoying_native="/home/disk1/jyhou/data/lessonNativeRecords/"
if [ ! -z $1 ]; then
    xiaoying_native=$1
fi

if [ ! -d $SWBD_DIR ]; then
  echo "Error:prepare_xiaoying_native.sh  requires a directory argument"
  exit 1;
fi


data_src_dir="data/local/xiaoying_native"
data_dir="data/xiaoying_native"

if [ -d $data_src_dir ]; then
    rm -r $data_src_dir
fi

mkdir -p $data_src_dir
mkdir -p $data_dir

find $xiaoying_native -name *.mp3 > $data_src_dir/mp3.list
find $xiaoying_native -name *.mp3 |sed -e "s:.mp3$::" > $data_src_dir/utter.list
#convert mp3 to wav and also downsampling them

find $xiaoying_native -name *.wav > $data_src_dir/wav.list
cat $data_src_dir/wav.list |sed -e "s:^$xiaoying_native::" -e "s:\(L.*/.*\)/.*.wav$:\1:" -e "s:\/:_:" > $data_src_dir/wav.id
paste $data_src_dir/wav.id $data_src_dir/wav.list |sort > $data_src_dir/wav.scp

rm $data_src_dir/text.raw
for item in `cat $data_src_dir/wav.list`;
do 
    file_dir=`dirname $item`
    file_name=$file_dir/text.txt
    cat $file_name >> $data_src_dir/text.raw
done
sed -e "s:[Pp]\.[Mm]\.:PM:" \
     -e "s:[Aa]\.[Mm]\.:AM:"\
     -e "s:^A[ ]:a :" \
     -e "s:\.[ ]A[ ]: a :" \
     -e "s:[,\.\?\!\"\]: :g"\
     -e "s:[-\:]: :g" \
     -e "s:  : :g" \
     -e "s:[ ]Mr[ ]: mister :" \
     -e "s:^Mr[ ]:mister :" \
     -e "s:[ ]Mr$: mister:" \
    $data_src_dir/text.raw > $data_src_dir/transcripts1.txt

paste $data_src_dir/wav.id $data_src_dir/transcripts1.txt |sort > $data_src_dir/transcripts2.txt

sort -c $data_src_dir/transcripts2.txt

# Remove SILENCE, <B_ASIDE> and <E_ASIDE>.

# Note: we have [NOISE], [VOCALIZED-NOISE], [LAUGHTER], [SILENCE].
# removing [SILENCE], and the <B_ASIDE> and <E_ASIDE> markers that mark
# speech to somone; we will give phones to the other three (NSN, SPN, LAU).
# There will also be a silence phone, SIL.
# **NOTE: modified the pattern matches to make them case insensitive

cat $data_src_dir/transcripts2.txt \
  | perl -ane 's:\s\[SILENCE\](\s|$):$1:gi;
               s/<B_ASIDE>//gi;
               s/<E_ASIDE>//gi;
               print;' \
  | awk '{if(NF > 1) { print; } } ' > $data_src_dir/transcripts3.txt

# case insensitive
./local/swbd1_map_words.pl -f 2- $data_src_dir/transcripts3.txt  > $data_src_dir/transcripts4.txt

#cat $data_src_dir/transcripts4.txt | tr 'A-Z' 'a-z' > $data_src_dir/text_fixed.txt
# format acronyms in text
python ./local/map_acronyms_transcripts.py -i $data_src_dir/transcripts4.txt \
    -o $data_src_dir/transcripts5.txt -M ./local/acronyms.map

cp $data_src_dir/transcripts5.txt $data_src_dir/text

#prepare the spk2utt file
paste $data_src_dir/wav.id $data_src_dir/wav.id |sort > $data_src_dir/spk2utt
cp $data_src_dir/spk2utt $data_src_dir/utt2spk
#spk2utt_to_utt2spk.pl $data_src_dir/spk2utt $data_src_dir/utt2spk

cp $data_src_dir/wav.scp \
   $data_src_dir/text \
   $data_src_dir/utt2spk \
   $data_src_dir/spk2utt $data_dir/

echo "xiao ying native data prepare succeeded"
utils/fix_data_dir.sh $data_dir
