#!/bin/bash

echo "$0 $@"
. ./cmd.sh
. ./path.sh

stage=1
export LC_ALL=C

config_file=conf/hcopy.config

if [ $stage -le 1 ]; then
    #for x in data_15_30  data_40_55  data_65_80  keywords_60_100_50  keywords_native;
    for x in keywords_60_100_50;
    do
        data_src=fbank/$x
        data_target=mfcc_htk/$x
        utils/copy_data_dir.sh  $data_src $data_target; rm $data_target/{feats,cmvn}.scp
        # prepare htk extract list
        cut -d" " -f2 ${data_target}/wav.scp | sed "s:^/home/disk1/jyhou/data/\(.*/.*/.*\).wav:/home/disk1/jyhou/data/\1.wav /home/disk1/jyhou/data/\1.mfcc:" > $data_target/htk.scp
        sed "s:.wav$:.mfcc:" ${data_target}/wav.scp > ${data_target}/mfcc_htk.scp

        log_dir=log/extract_htk_mfcc/
        job_num=20
        tmp_list_dir=`mktemp -d temp.XXXX`
        list_file_base_name=`basename $data_target/htk.scp`
        mkdir -p ${log_dir}
        python local/split.py $data_target/htk.scp $tmp_list_dir/ $job_num
        run.pl JOB=1:$job_num $log_dir/extract_htk_feature_${x}.JOB.log \
            HCopy -C $config_file -S ${tmp_list_dir}/${list_file_base_name}JOB
        rm -r $tmp_list_dir

        mkdir -p ${data_target}/data
        copy-feats --htk-in=true scp:${data_target}/mfcc_htk.scp ark,scp:${data_target}/data/mfcc.ark,${data_target}/data/mfcc.scp
        cp ${data_target}/data/mfcc.scp ${data_target}/feats.scp
        steps/compute_cmvn_stats.sh $data_target/ $data_target/log $data_target/data

    done
fi
