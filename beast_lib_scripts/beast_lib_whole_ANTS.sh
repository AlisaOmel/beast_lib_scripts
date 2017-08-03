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
LibPath='/home/aomelche/library_NFBS_ANTS/NFBS'
MNIHeadTemplatePATH='/usr/share/fsl/5.0/data/standard/MNI152_T1_1mm.nii.gz'

inputDir=$(dirname $1)
filename=$(basename $1)
inputFile=$inputDir/$filename

file=${inputFile%.nii.gz}
fname=${filename%.nii.gz}

mkdir -p /home/aomelche/library_NFBS_ANTS/NFBS/transform_files

# normalize data using ANTS
echo Normalizing stx images...
antsRegistration --collapse-output-transforms 0 --dimensionality 3 --initial-moving-transform [$MNIHeadTemplatePATH,$inputFile,0] --interpolation Linear --output [${LibPath}/transform_files/${fname}_transform,${file}_Warped.nii.gz] --transform Rigid[0.1] --metric MI[$MNIHeadTemplatePATH,$inputFile,1,32,Regular,0.25] --convergence [1000x500x250x100,1e-08,10] --smoothing-sigmas 3.0x2.0x1.0x0.0 --shrink-factors 8x4x2x1 --use-histogram-matching 1 --transform Affine[0.1] --metric MI[$MNIHeadTemplatePATH,$inputFile,1,32,Regular,0.25] --convergence [1000x500x250x100,1e-08,10] --smoothing-sigmas 3.0x2.0x1.0x0.0 --shrink-factors 8x4x2x1 --use-histogram-matching 1 --transform SyN[0.1,3.0,0.0] --metric CC[$MNIHeadTemplatePATH,$inputFile,1,4] --convergence [100x100x70x20,1e-09,15] --smoothing-sigmas 3.0x2.0x1.0x0.0 --shrink-factors 6x4x2x1 --use-histogram-matching 1 --winsorize-image-intensities [0.01,0.99]

echo Normalizing mask images ....
antsApplyTransforms --default-value 0 --dimensionality 3 --input ${LibPath}/masks/${fname}.nii.gz --input-image-type 0 --interpolation NearestNeighbor --output ${LibPath}/masks/${fname}_Warped.nii.gz --reference-image $MNIHeadTemplatePATH --transform ${LibPath}/transform_files/${fname}_transform3Warp.nii.gz --transform ${LibPath}/transform_files/${fname}_transform2Affine.mat --transform ${LibPath}/transform_files/${fname}_transform1Rigid.mat --transform ${LibPath}/transform_files/${fname}_transform0DerivedInitialMovingTranslation.mat

echo Sending to MNC...
/opt/minc-itk4/bin/nii2mnc ${file}_Warped.nii.gz ${file}.mnc
/opt/minc-itk4/bin/nii2mnc ${LibPath}/masks/${fname}_Warped.nii.gz ${LibPath}/masks/${fname}.mnc

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

#mv ${LibPath}/masks/${fname}.nii.gz ${LibPath}/masks/intermediate_files
#mv ${file}.nii.gz ${LibPath}/stx/finished_subjects/

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

