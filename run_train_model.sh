# train bottleneck neural network using only SWBD data
bash run_dnn_tandem_uc.sh

# prepare Xiaoying's data
bash run_data_prepare.sh

# train bottleneck neual network using Xiaoying's data
bash run_train_sbnf_transfer.sh

# train bottleneck neual network using both XiaoYing and SWBD data
#bash run_train_sbnf.sh

# extract bottleneck feature for Xiaoying's test data and convert them to HTK format
bash run_extract_feature.sh

