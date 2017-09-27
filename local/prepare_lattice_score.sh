#!/bin/bash

echo "$0 $@"
nnetdir=
feat_dir=
for x in data_15_30 data_40_55 data_65_80; 
do
    resultdir=$nnetdir/$x/kws
    outdir=results/${x}_lattice
    utter_id_file=$feat_dir/$x/utter_id
    cat $resultdir/result.*.gz | gunzip -c > $resultdir/result.txt 
    python local/prepare_lattice_score.py $resultdir/result.txt $utter_id_file \
        $outdir
done
# 
