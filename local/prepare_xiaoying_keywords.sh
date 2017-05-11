export LC_ALL=C

for x in keywords_55_60 keywords_75_80 keywords_95_100 keywords_native;
do
    data_dir=/mnt/jyhou/data/XiaoYing_STD/$x
    mkdir data/local/$x/
    find /mnt/jyhou/data/XiaoYing_STD/$x -name *.wav > data/local/$x/wav.list
    sed -e "s:^/mnt/jyhou/data/XiaoYing_STD/$x/::" -e "s:.wav$::" data/local/$x/wav.list > data/local/$x/wav.id
    paste data/local/$x/wav.id data/local/$x/wav.list |sort > data/$x/wav.scp
    paste data/local/$x/wav.id data/local/$x/wav.id |sort > data/$x/spk2utt
    cp data/$x/spk2utt data/$x/utt2spk
    utils/fix_data_dir.sh data/$x
    cat data/local/$x/wav.id |sort >/mnt/jyhou/feats/XiaoYing_STD/list/${x}_all.list
done
