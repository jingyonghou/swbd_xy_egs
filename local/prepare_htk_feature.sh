#!/bin/bash

echo "$0 $@"
. ./cmd.sh
. ./path.sh

stage=1
export LC_ALL=C

config_file=conf/hcopy.config

if [ $stage -le 1 ]; then
    for x in xiaoying_train1 xiaoying_train2; 
    do
        data_src=fbank/$x
        data_target=mfcc_htk/$x
        utils/copy_data_dir.sh  $data_src $data_target; rm $data_target/{feats,cmvn}.scp
        # prepare htk extract list 
        cut -d" " -f2 ${data_target}/wav.scp | sed "s:^/home/disk1/jyhou/data/\(.*/.*/.*/.*\).wav:/home/disk1/jyhou/data/\1.wav /home/disk1/jyhou/data/\1.mfcc:" > $data_target/htk.scp
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

if [ $stage -le 2 ]; then
    feature_dir=mfcc_htk
    for x in xiaoying_train1 xiaoying_train2;
    do
        utils/data/remove_dup_utts.sh 200 ${feature_dir}/${x} ${feature_dir}/${x}_nodup_200
        utils/data/remove_dup_utts.sh 100 ${feature_dir}/${x} ${feature_dir}/${x}_nodup_100
    done
    
    
    for x in train_nodup xiaoying_train1_nodup_200 xiaoying_train1_nodup_100 xiaoying_train2_nodup_200 xiaoying_train2_nodup_100;
    do
        utils/subset_data_dir_tr_cv.sh ${feature_dir}/$x ${feature_dir}/${x}_tr90 ${feature_dir}/${x}_cv10
    done
    
    local/merge_data.sh ${feature_dir}/xiaoying_train1_nodup_200_tr90 ${feature_dir}/xiaoying_train2_nodup_200_tr90 ${feature_dir}/xiaoying_train_nodup_200_tr90
    local/merge_data.sh ${feature_dir}/xiaoying_train1_nodup_200_cv10 ${feature_dir}/xiaoying_train2_nodup_200_cv10 ${feature_dir}/xiaoying_train_nodup_200_cv10
    
    local/merge_data.sh ${feature_dir}/xiaoying_train1_nodup_100_tr90 ${feature_dir}/xiaoying_train2_nodup_100_tr90 ${feature_dir}/xiaoying_train_nodup_100_tr90
    local/merge_data.sh ${feature_dir}/xiaoying_train1_nodup_100_cv10 ${feature_dir}/xiaoying_train2_nodup_100_cv10 ${feature_dir}/xiaoying_train_nodup_100_cv10
    
    local/merge_data.sh ${feature_dir}/train_nodup_tr90 ${feature_dir}/xiaoying_train_nodup_100_tr90 ${feature_dir}/swbd_xy_train_nodup_100_tr90
    local/merge_data.sh ${feature_dir}/train_nodup_tr90 ${feature_dir}/xiaoying_train_nodup_200_tr90 ${feature_dir}/swbd_xy_train_nodup_200_tr90

    local/merge_data.sh ${feature_dir}/train_nodup_cv10 ${feature_dir}/xiaoying_train_nodup_100_cv10 ${feature_dir}/swbd_xy_train_nodup_100_cv10
    local/merge_data.sh ${feature_dir}/train_nodup_cv10 ${feature_dir}/xiaoying_train_nodup_200_cv10 ${feature_dir}/swbd_xy_train_nodup_200_cv10
fi

if [ $stage -le 0 ]; then
    for x in train_nodup; 
    do
        data_src=fbank/$x
        data_target=mfcc_htk/$x
        utils/copy_data_dir.sh  $data_src $data_target; rm $data_target/{feats,cmvn}.scp
        wav_output_dir=/home/disk1/jyhou/data/${x}_wave
        mkdir -p $wav_output_dir
        #prepare wav-copy scp list
        cut -d" " -f1  $data_target/segments |sed "s:\(^..*$\):\1 ${wav_output_dir}/\1.wav:" >${data_target}/segments_wav.scp
        #prepare htk extract list
        cut -d" " -f1  $data_target/segments |sed "s:\(^..*$\):${wav_output_dir}/\1.wav ${wav_output_dir}/\1.mfcc:" >${data_target}/htk.scp
    
        sed "s:.wav$:.mfcc:" ${data_target}/segments_wav.scp > ${data_target}/mfcc_htk.scp
        extract-segments scp:$data_target/wav.scp $data_target/segments ark:- |wav-copy ark:- scp:${data_target}/segments_wav.scp
    
        #extract mfcc using htk
    
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
