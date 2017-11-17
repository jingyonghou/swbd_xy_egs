. ./path.sh
. ./cmd.sh
LM=data/local/lm/faker.arpa.gz
srilm_opts="-subset -prune-lowprobs -unk -tolower -order 1"

out_dir="data/lang_fakerG"
tmpdir=$(mktemp -d /tmp/kaldi.XXXX);
awk '{print $1}' $out_dir/words.txt > $tmpdir/voc || exit 1;

change-lm-vocab -vocab $tmpdir/voc -lm $LM -write-lm  $out_dir/faker.arpa $srilm_opts

arpa2fst --disambig-symbol=#0 --read-symbol-table=$out_dir/words.txt $out_dir/faker.arpa $out_dir/G.fst || exit 1

