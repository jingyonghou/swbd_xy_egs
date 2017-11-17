#!/bin/bash

nj=20
config="conf/decode_dnn.config"
acwt=0.08333
beam=25.0
lattice_beam=15.0

echo "$0 $@"
. ./cmd.sh
. ./path.sh
. parse_options.sh || exit 1;


if [ $# != 4 ]; then
    echo "Usage: $0 <datadir> <gmmdir> <graphdir> <nnetdir> <decodedir>" 
    echo "e.g.: $0 data/dev exp/tri4 exp/tri4/graph exp/dnn exp/dnn "
    exit 1;
fi

datadir=$1
gmmdir=$2
graphdir=$3
nnetdir=$4

steps/nnet/decode.sh --nj $nj --cmd "$decode_cmd" --config $config --acwt $acwt \
   --beam $beam --lattice-beam $lattice_beam $graphdir $datadir $nnetdir
