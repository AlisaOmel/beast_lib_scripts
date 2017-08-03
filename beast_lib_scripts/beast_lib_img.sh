#!/usr/bin/env bash
# 
# Set up library for beast with nifti
# 
# Ben Puccio
# 2016-07-07
#  
# ECHO config files at bottom of script doesnt work (library.masks.1mm, etc.)
# Still need to copy other config files from another library (default.1mm.conf, etc.)

# set the timing
SECONDS=0

source /opt/minc/minc-toolkit-config.sh
LibPath='/home/aomelche/library_NFBS_ben/NFBS'
MNItemplatePATH='/opt/minc/share/icbm152_model_09c'



# copy anatomical skull on images to library and rename
echo Copying images to library...
a=0
for i in $(ls /home/aomelche/skull_strip/anat_2/*T1w.nii.gz); do
    if [ "$a" -gt 9 ]; then 
        3dcopy $i $LibPath/stx/000"${a}".nii
    else
        3dcopy $i $LibPath/stx/0000"${a}".nii
    fi
    a=$((a+1));
done

echo Copying images to library...
b=0
for i in $(ls /home/aomelche/skull_strip/mask_files/*_edit.nii.gz); do
    if [ "$b" -gt 9 ]; then 
        3dcopy $i $LibPath/masks/000"${b}".nii
    else
        3dcopy $i $LibPath/masks/0000"${b}".nii
    fi
    b=$((b+1));
done


duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"

