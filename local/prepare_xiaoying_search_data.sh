export LC_ALL=C


for x in data_55_60 data_75_80 data_95_100; 
do
    data_dir=/mnt/jyhou/data/XiaoYing_STD/$x
    sed -e "s:\(^L.*\)\b\(L.*.wav$\):\1 $data_dir/\2:" data/local/$x/wav.scp > data/local/$x/wav_new.scp
    mkdir -p data/$x
    cat data/local/$x/wav_new.scp |sort > data/$x/wav.scp
    cut -d" " -f 1 data/local/$x/wav_new.scp > data/local/$x/wav.id
    paste data/local/$x/wav.id data/local/$x/wav.id |sort > data/$x/spk2utt
    cp data/$x/spk2utt data/$x/utt2spk
    cat data/text.txt |sort > data/$x/text
    utils/fix_data_dir.sh data/$x
done
