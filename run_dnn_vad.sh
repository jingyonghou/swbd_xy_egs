#!/bin/bash

stage=4
cmd=run.pl
nj=20

echo "$0 $@" 
[ -f cmd.sh ] && . ./cmd.sh
[ -f path.sh ] && . ./path.sh

. parse_options.sh || exit 1;


# prepare the tr and cv set

# prepare the target for training DNN based VAD

# VAD evaluation

# do the VAD for the STD test data (keywords data and test utterances)

