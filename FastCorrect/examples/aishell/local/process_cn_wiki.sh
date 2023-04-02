WIKI_PROCESS_DIR=../../../../corpus_process_script
TN_PROCESS_DIR=../../../../chinese_text_normalization
TOOL_DIR=../../tools
input_file=

. local/parse_options.sh

name=$(basename $input_file|sed 's|\.xml.bz2||')
save_dir=$(dirname $input_file)
ori_text=$save_dir/$name.ori.txt
q2b_text=$save_dir/$name.q2b.txt
t2s_text=$save_dir/$name.t2s.txt
seg_text=$save_dir/$name.seg.txt
no_blank_text=$save_dir/$name.no_blank.txt
tn_text=$save_dir/$name.tn.txt
clean_text=$save_dir/$name.clean.txt
split_text=$save_dir/$name.split.txt

echo "*************** Extract wiki text ***************"

python3 $WIKI_PROCESS_DIR/wikidata_process/wiki_process.py $input_file $ori_text

cat $ori_text|head -n 1

echo "*************** Str2Q2B ***************"
python3 $WIKI_PROCESS_DIR/StrQ2B/strQ2B.py --input $ori_text --output $q2b_text

cat $q2b_text|head -n 1

echo "*************** T2S ***************"
python3 $WIKI_PROCESS_DIR/chinese_t2s/chinese_t2s.py --input $q2b_text --output $t2s_text

cat $t2s_text|head -n 1

echo "*************** Segment sentence ***************"
python3 $TOOL_DIR/segment_sentence.py $t2s_text > $seg_text

cat $seg_text|head

echo "*************** TN ***************"
python3 $TN_PROCESS_DIR/python/cn_tn.py $seg_text $tn_text

echo "*************** Clean text ***************"
python3 $WIKI_PROCESS_DIR/clean/clean_corpus.py --input $tn_text --output $clean_text

cat $clean_text|shuf -n 10

echo "*************** Remove blank line ***************"
sed ' /^$/d' $clean_text > $no_blank_text

cat  $no_blank_text|shuf -n 10

echo "*************** Split text ***************"
python3 -u $WIKI_PROCESS_DIR/split_zh_char/split_zh_char.py --input $no_blank_text --output $split_text

cat $split_text|head


echo "*************** Add noise to text ***************"
for i in {1..5};do
    echo "epoch $i"
    cur_noise_file=$save_dir/$name.add_noise.txt.${i}
    python3 ../../scripts/add_noise_new.py $split_text $cur_noise_file $i ../../script/chinese_char_sim.txt
done


echo "*************** Get Ref and Hyp text ***************"
for i in {1..5};do
    echo "epoch $i"
    cur_ref_file=$save_dir/$name.ref.txt.${i}
    cur_hyp_file=$save_dir/$name.hyp.txt.${i}
    awk -F '\t' '{print($1)}' $cur_noise_file > $cur_ref_file
    awk -F '\t' '{print($2)}' $cur_noise_file > $cur_hyp_file
done

echo "*************** Get Ref and Hyp text ***************"


for i in {1..5};do
    echo "epoch $i"
    cur_ref_file=$save_dir/$name.ref.txt.${i}
    cur_hyp_file=$save_dir/$name.hyp.txt.${i}
    python3 ../../scripts/align_cal_werdur_v2.py $cur_hyp_file  $cur_ref_file
done
cat $save_dir/$name.ref.txt.*.tgt > $dir/train.tgt
cat $save_dir/$name.hyp.txt.*.src.werdur.full > $dir/train.src





