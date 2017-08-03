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

inputDir=$(dirname $1)
filename=$(basename $1)
inputFile=$inputDir/$filename

file=${inputFile%.nii}
fname=${filename%.nii}

# normalize data using beast_normalize
echo Normalizing stx images...
/opt/minc-itk4/bin/nii2mnc $inputFile ${file}_notnorm.mnc;
mv ${inputFile} ${LibPath}/stx/intermediate_files
/opt/minc-itk4/bin/beast_normalize ${file}_notnorm.mnc ${file}.mnc ${file}_anat2mni.xfm -modeldir $MNItemplatePATH
mv ${file}_notnorm.mnc ${LibPath}/stx/intermediate_files

echo Normalizing mask images ....
/opt/minc-itk4/bin/nii2mnc ${LibPath}/masks/${fname}.nii ${LibPath}/masks/${fname}_notnorm.mnc
/opt/minc-itk4/bin/mincresample ${LibPath}/masks/${fname}_notnorm.mnc ${LibPath}/masks/${fname}.mnc -tfm_input_sampling -transformation ${LibPath}/stx/${fname}_anat2mni.xfm -like /home/aomelche/library_NFBS/NFBS/stx/1mm/00000.mnc 

# flip head volume and downsample
echo Flipping stx images and downsampling...	
/opt/minc-itk4/bin/flip_volume ${file}.mnc ${file}_flip.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 2 ${file}.mnc ${file}_2.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 4 ${file}.mnc ${file}_4.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 2 ${file}_flip.mnc ${file}_flip_2.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 4 ${file}_flip.mnc ${file}_flip_4.mnc

# make separate folders for differenet resolutions of stx
echo Separating into folders...
mv ${file}.mnc ${LibPath}/stx/1mm/${fname}.mnc
mv ${file}_flip.mnc ${LibPath}/stx/1mm/${fname}_flip.mnc

mv ${file}_2.mnc ${LibPath}/stx/2mm/${fname}.mnc
mv ${file}_flip_2.mnc ${LibPath}/stx/2mm/${fname}_flip.mnc

mv ${file}_4.mnc ${LibPath}/stx/4mm/${fname}.mnc
mv ${file}_flip_4.mnc ${LibPath}/stx/4mm/${fname}_flip.mnc

mv ${LibPath}/masks/${fname}.nii ${LibPath}/masks/intermediate_files
mv ${LibPath}/stx/${fname}_anat2mni.xfm ${LibPath}/stx/intermediate_files
mv ${LibPath}/masks/${fname}_notnorm.mnc ${LibPath}/masks/intermediate_files

echo Flipping mask images and downsampling...	
/opt/minc-itk4/bin/flip_volume ${LibPath}/masks/${fname}.mnc ${LibPath}/masks/${fname}_flip.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 2 ${LibPath}/masks/${fname}.mnc ${LibPath}/masks/${fname}_2.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 4 ${LibPath}/masks/${fname}.mnc ${LibPath}/masks/${fname}_4.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 2 ${LibPath}/masks/${fname}_flip.mnc ${LibPath}/masks/${fname}_flip_2.mnc
/opt/minc-itk4/bin/minc_downsample --3dfactor 4 ${LibPath}/masks/${fname}_flip.mnc ${LibPath}/masks/${fname}_flip_4.mnc


# make separate folders for differenet resolutions of masks
mv ${LibPath}/masks/${fname}.mnc ${LibPath}/masks/1mm/${fname}.mnc
mv ${LibPath}/masks/${fname}_flip.mnc ${LibPath}/masks/1mm/${fname}_flip.mnc

mv ${LibPath}/masks/${fname}_2.mnc ${LibPath}/masks/2mm/${fname}.mnc
mv ${LibPath}/masks/${fname}_flip_2.mnc ${LibPath}/masks/2mm/${fname}_flip.mnc

mv ${LibPath}/masks/${fname}_4.mnc ${LibPath}/masks/4mm/${fname}.mnc
mv ${LibPath}/masks/${fname}_flip_4.mnc ${LibPath}/masks/4mm/${fname}_flip.mnc

duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"

