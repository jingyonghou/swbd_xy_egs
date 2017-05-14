python local/get_read_afterme_speaker.py /mnt/jyhou/data/userTextAudio/json.list data/read_after_me_train1/wav.scp read_afterme_train_speaker.list
python local/get_read_afterme_speaker.py /mnt/jyhou/data/userTextAudio/json.list data/read_after_me_test/wav.scp read_afterme_test_speaker.list
python local/get_pronunciation_challenge_speaker.py data/pronunciation_challenge/wav.scp pronunciation_challenge_train_speaker.list

cat pronunciation_challenge_train_speaker.list read_afterme_train_speaker.list |sort|uniq > exclude_speaker.list

python local/exclude_list_by_speaker.py /mnt/jyhou/data/userTextAudio/json.list exclude_speaker.list data/read_after_me_test/wav.scp read_afterme_test_remain.scp
