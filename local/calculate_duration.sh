echo "read after me 100"
feat-to-len scp:fbank/xiaoying_train1_nodup_100/feats.scp ark,t:-|cut -d" " -f2 |awk 'BEGIN{total=0}{total+=$1}END{print total/360000}'
echo "pronunciation challenge 100"
feat-to-len scp:fbank/xiaoying_train2_nodup_100/feats.scp ark,t:-|cut -d" " -f2 |awk 'BEGIN{total=0}{total+=$1}END{print total/360000}'
echo "read after me 200"
feat-to-len scp:fbank/xiaoying_train1_nodup_200/feats.scp ark,t:-|cut -d" " -f2 |awk 'BEGIN{total=0}{total+=$1}END{print total/360000}'
echo "pronunciation challenge 200"
feat-to-len scp:fbank/xiaoying_train2_nodup_200/feats.scp ark,t:-|cut -d" " -f2 |awk 'BEGIN{total=0}{total+=$1}END{print total/360000}'
