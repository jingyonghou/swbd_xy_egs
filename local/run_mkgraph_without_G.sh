. ./path.sh
. ./cmd.sh

graph_dir=exp/tri4/graph_fakerG
$train_cmd $graph_dir/mkgraph.log utils/mkgraph.sh data/lang_fakerG exp/tri4 $graph_dir
