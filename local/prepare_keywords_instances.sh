keyword_list=data/info/keywords.list
ctm_file=exp/nn_xiaoying_native_ali/ctm
native_wav_scp=data/xiaoying_native/wav.scp
max_num=5
output_dir=/mnt/jyhou/data/XiaoYing_STD/keywords_native/
mkdir -p $output_dir

echo "python ./local/prepare_keywords_instances.py $keyword_list $ctm_file $native_wav_scp $max_num $output_dir"
python ./local/prepare_keywords_instances.py $keyword_list $ctm_file $native_wav_scp $max_num $output_dir

