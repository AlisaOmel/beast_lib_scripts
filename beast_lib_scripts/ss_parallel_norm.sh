export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=5 
mkdir -p /home/aomelche/library_NFBS_ben_additions/log
ls /home/aomelche/library_NFBS_ben_additions/NFBS/stx/*.nii | parallel -j 7 '/home/aomelche/library_NFBS_ben_additions/beast_lib_whole.sh {} > /home/aomelche/library_NFBS_ben_additions/log/ss_{#}.log 2>&1'
