export LC_ALL=C

for x in keywords_60_100_50
#keywords_60_80_50_selected keywords_80_100_50_selected # keywords_20_60 keywords_60_100 keywords_native;
do
    data_dir=/home/disk1/jyhou/data/XiaoYing_STD/$x
    mkdir -p data/local/$x/
    mkdir -p data/$x
    find $data_dir -name *.wav > data/local/$x/wav.list
    sed -e "s:^${data_dir}/::" -e "s:.wav$::" -e "s: :-:" data/local/$x/wav.list > data/local/$x/wav.id
    paste data/local/$x/wav.id data/local/$x/wav.list |sort > data/$x/wav.scp
    paste data/local/$x/wav.id data/local/$x/wav.id |sort > data/$x/spk2utt
    cp data/$x/spk2utt data/$x/utt2spk
    utils/fix_data_dir.sh data/$x
done
