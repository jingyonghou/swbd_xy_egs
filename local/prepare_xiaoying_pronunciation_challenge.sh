export LC_ALL=C
for x in pronunciation_challenge;
do
    data_dir=data/info
    scp_file=$data_dir/pronunciation_challenge.scp
    text_file=$data_dir/pronunciation_challenge.text
    mkdir -p data/local/$x/
    mkdir -p data/$x/
    cp $scp_file data/local/$x/wav.scp
    cut -f1 $text_file > data/local/$x/wav.id
    cut -f2 $text_file > data/local/$x/text.raw

    cat data/local/$x/text.raw |tr "[A-Z]" "[a-z]" > data/local/$x/text_lowercase.raw
    sed -e "s:[Pp]\.[Mm]\.:PM:" \
         -e "s:[Aa]\.[Mm]\.:AM:"\
         -e "s:^A[ ]:a :" \
         -e "s:\.[ ]A[ ]: a :" \
         -e "s:[,\.\?\!\"\]: :g"\
         -e "s:[-\:]: :g" \
         -e "s:  : :g" \
         -e "s:[ ]mr[ ]: mister :" \
         -e "s:^mr[ ]:mister :" \
         -e "s:[ ]mr$: mister:" \
        data/local/$x/text_lowercase.raw > data/local/$x/transcripts1.txt
    
    paste data/local/$x/wav.id data/local/$x/transcripts1.txt |sort > data/local/$x/transcripts2.txt
    
    sort -c data/local/$x/transcripts2.txt
    
    # Remove SILENCE, <B_ASIDE> and <E_ASIDE>.
    
    # Note: we have [NOISE], [VOCALIZED-NOISE], [LAUGHTER], [SILENCE].
    # removing [SILENCE], and the <B_ASIDE> and <E_ASIDE> markers that mark
    # speech to somone; we will give phones to the other three (NSN, SPN, LAU).
    # There will also be a silence phone, SIL.
    # **NOTE: modified the pattern matches to make them case insensitive
    
    cat data/local/$x/transcripts2.txt \
      | perl -ane 's:\s\[SILENCE\](\s|$):$1:gi;
                   s/<B_ASIDE>//gi;
                   s/<E_ASIDE>//gi;
                   print;' \
      | awk '{if(NF > 1) { print; } } ' > data/local/$x/transcripts3.txt
    
    # case insensitive
    ./local/swbd1_map_words.pl -f 2- data/local/$x/transcripts3.txt  > data/local/$x/transcripts4.txt
    
    # format acronyms in text
    python ./local/map_acronyms_transcripts.py -i data/local/$x/transcripts4.txt \
    -o data/local/$x/transcripts5.txt -M ./local/acronyms.map
    cp data/local/$x/transcripts5.txt data/local/$x/text


    cat data/local/$x/wav.scp |sort > data/$x/wav.scp
    cat data/local/$x/text |sort > data/$x/text
    paste data/local/$x/wav.id data/local/$x/wav.id |sort > data/$x/spk2utt 
    cp data/$x/spk2utt data/$x/utt2spk
    utils/fix_data_dir.sh data/$x
done
