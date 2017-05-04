export LC_ALL=C
for x in read_after_me_all;
do
    data_dir=/mnt/jyhou/data/XiaoYing_All
    mkdir -p data/local/$x/
    mkdir -p data/$x/
    find $data_dir -name *.wav > data/local/$x/wav.list
    sed -e "s:^/mnt/jyhou/data/XiaoYing_All/::" -e "s:.wav$::" -e "s:/:_:" data/local/$x/wav.list > data/local/$x/wav.id
    paste data/local/$x/wav.id data/local/$x/wav.list |sort > data/$x/wav.scp
    paste data/local/$x/wav.id data/local/$x/wav.id |sort > data/$x/spk2utt
    cp data/$x/spk2utt data/$x/utt2spk
    echo "python local/prepare_text.py data/info/text.dict data/local/$x/wav.id data/local/$x/text"
    python local/prepare_text.py data/info/text.dict data/local/$x/wav.id data/local/$x/text
    cat data/local/$x/text |sort > data/$x/text
    utils/fix_data_dir.sh data/$x
done
