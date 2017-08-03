#!/usr/bin/env bash
# 
# BEaSTSkullStrip.sh
# Using BEaST to do SkullStriping
# [see here](https://github.com/FCP-INDI/C-PAC/wiki/Concise-Installation-Guide-for-BEaST) for instructions for BEaST.
# 
# 
# Alisa Omelchenko and Benjamin Puccio, shell script for implemenatation of BEaST
# Based off of (minor changes to):
#
# Qingyang Li
# 2013-07-29
#  
# The script requires AFNI, BEaST, MINC, and ANTS toolkit. 

do_anyway=1

# set the timing
SECONDS=0

MincPATH='/opt/minc-itk4'
source ${MincPATH}/minc-toolkit-config.sh

MincLibPATH='/home/aomelche/library_NFBS_ANTS'
NumLibImgs=25

MNIHeadTemplatePATH='/usr/share/fsl/5.0/data/standard/MNI152_T1_1mm.nii.gz'

cwd=`pwd`

if [ $# -lt 1  ]
then 
  echo " USAGE ::  "
  echo "  beastskullstrip.sh <input> [output prefix] " 
  echo "   input: anatomical image with skull, in nifti format " 
  echo "   output: The program will output: " 
  echo "      1) a skull stripped brain image in scanner space; "  
  echo "      2) skull stripped brain masks in mni spcae and scanner space. "
  echo "      3) anatomical image transformed to mni space using non-linear transforms "
  echo "      4) minc files of brain mask and anatomical, both in mni space (for beast library)"
  echo "   Option: output prefix: the filename of the output files without extention"
  echo " Example: beastskullstrip.sh ~/data/head.nii.gz ~/brain "
  exit
fi

if [ $# -ge 1 ]
then
    inputDir=$(dirname $1)
    if [ $inputDir == "." ]
    then
        inputDir=$cwd
    fi

    filename=$(basename $1)
    inputFile=$inputDir/$filename

    extension="${filename##*.}"
    if [ $extension == "gz" ]
    then
        filename="${filename%.*}"
    fi

    filename="${filename%.*}"
    out=$inputDir/$filename
fi

if [ $# -ge 2 ]
then
    outputDir=$(dirname $2)
    if [ $outputDir == "." ]
    then
        outputDir=$cwd
        out=$outputDir/$2
    else
        mkdir -p $outputDir
        out=$2
    fi
fi

workingDir=`mktemp -d`
#workingDir=`pwd`
echo " ++ working directory is $workingDir"
cd $workingDir

if [ ! -f head.nii ]
then 
   # 3dcopy $inputFile head.nii
    3dresample -orient LPI -prefix head.nii -inset $inputFile
fi

# Normalize the input
if [ ! -f head_mni.nii ] && [ ! -f transform3Warp.nii.gz ] || [ $do_anyway -eq 1 ] 
then
    antsRegistration --collapse-output-transforms 0 --dimensionality 3 --initial-moving-transform [$MNIHeadTemplatePATH,head.nii,0] --interpolation Linear --output [transform,head_mni.nii] --transform Rigid[0.1] --metric MI[$MNIHeadTemplatePATH,head.nii,1,32,Regular,0.25] --convergence [1000x500x250x100,1e-08,10] --smoothing-sigmas 3.0x2.0x1.0x0.0 --shrink-factors 8x4x2x1 --use-histogram-matching 1 --transform Affine[0.1] --metric MI[$MNIHeadTemplatePATH,head.nii,1,32,Regular,0.25] --convergence [1000x500x250x100,1e-08,10] --smoothing-sigmas 3.0x2.0x1.0x0.0 --shrink-factors 8x4x2x1 --use-histogram-matching 1 --transform SyN[0.1,3.0,0.0] --metric CC[$MNIHeadTemplatePATH,head.nii,1,4] --convergence [100x100x70x20,1e-09,15] --smoothing-sigmas 3.0x2.0x1.0x0.0 --shrink-factors 6x4x2x1 --use-histogram-matching 1 --winsorize-image-intensities [0.01,0.99]
fi

#MINC formating
if [ ! -f head_mni.mnc ]
then
    nii2mnc head_mni.nii head_mni.mnc
fi

# Run BEaST to do SkullStripping
# configuration file can be replaced by $MincLibPATH/default.2mm.conf or $MincLibPATH/default.4mm.conf

if [ ! -f brain_mask_mni.mnc ] || [ $do_anyway -eq 1 ]
then
    mincbeast -selection_num $NumLibImgs -verbose -same_res -median -fill -conf $MincLibPATH/default.1mm.conf $MincLibPATH head_mni.mnc brain_mask_mni.mnc
fi

#Back to .nii

if [ ! -f brain_mask_mni.nii ] || [ $do_anyway -eq 1 ]
then
    mnc2nii brain_mask_mni.mnc brain_mask_mni.nii
fi

# Trasform brain mask to it's original space
if [ ! -f brain_mask.nii ] || [ $do_anyway -eq 1 ]
then
    antsApplyTransforms --default-value 0 --dimensionality 3 --input brain_mask_mni.nii --input-image-type 0 --interpolation NearestNeighbor --output brain_mask_orig.nii --reference-image head.nii --transform [transform0DerivedInitialMovingTranslation.mat,1] --transform [transform1Rigid.mat,1] --transform [transform2Affine.mat,1] --transform transform3InverseWarp.nii.gz
fi

# Generate and output brain image and brain mask
if [ ! -f head_brain.nii.gz ] || [ $do_anyway -eq 1 ]
then
    3dcalc -a brain_mask_orig.nii -b head.nii -expr "step(a)*b" -prefix head_brain.nii.gz
fi
# fix the AFNI won't overwrite problem.
rm -rf ${out}_brainmask.nii.gz ${out}_brain.nii.gz ${out}_head_mni.nii.gz ${out}_brain_mask_mni.nii.gz ${out}_head_mni.mnc ${out}_brain_mask_mni.mnc ${out}_transform3Warp.nii.gz ${out}_transform2Affine.mat ${out}_transform1Rigid.mat ${out}_transform0DerivedInitialMovingTranslation.mat

3dcopy brain_mask_orig.nii ${out}_brainmask.nii.gz
3dcopy head_brain.nii.gz ${out}_brain.nii.gz
3dcopy brain_mask_mni.nii ${out}_brain_mask_mni.nii.gz
3dcopy head_mni.nii ${out}_head_mni.nii.gz
3dcopy transform3Warp.nii.gz ${out}_transform3Warp.nii.gz
3dcopy transform3InverseWarp.nii.gz ${out}_transform3InverseWarp.nii.gz
mv head_mni.mnc ${out}_head_mni.mnc
mv brain_mask_mni.mnc ${out}_brain_mask_mni.mnc
mv transform2Affine.mat ${out}_transform2Affine.mat
mv transform1Rigid.mat ${out}_transform1Rigid.mat
mv transform0DerivedInitialMovingTranslation.mat ${out}_transform0DerivedInitialMovingTranslation.mat

echo "  ++ working directory is $workingDir"
cd $cwd

duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
 
