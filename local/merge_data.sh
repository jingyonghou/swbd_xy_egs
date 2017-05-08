#!/bin/bash

if [ $# != 3 ]; then
    echo "Usage: merge_data.sh <srcdir_1> <srcdir_2> <destdir>"
fi

export LC_ALL=C;

srcdir_1=$1
srcdir_2=$2
destdir=$3

if [ -d $destdir ]; then 
    rm -r $destdir
fi

mkdir -p $destdir

for x in cmvn.scp feats.scp spk2utt text utt2spk;
do
    echo "cat $srcdir_1/$x $srcdir_2/$x| sort > $destdir/$x"
    cat $srcdir_1/$x $srcdir_2/$x| sort > $destdir/$x
done


