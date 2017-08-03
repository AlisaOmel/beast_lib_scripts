
source /opt/minc/minc-toolkit-config.sh
LibPath='/home/aomelche/library_NFBS/'
MNItemplatePATH='/opt/minc/share/atlas'
# This script makes a union_mask, intersection_mask, and margin_mask based on the mask files in the NFBS/masks/1mm directory. If subject files are added or deleted in the NFBS directory, this script must be rerun to mimic the changes in the skullstripping scripts that utilize this library. 


# make or get config files
echo Making config files...
for i in 1 2 4
do
    for f in $(ls -1 ${LibPath}/NFBS/stx/${i}mm/*.mnc); do g=$(basename $f); echo NFBS/stx/${i}mm/$g; done >> ${LibPath}/library.stx.${i}mm
    for f in $(ls -1 ${LibPath}/NFBS/masks/${i}mm/*.mnc); do g=$(basename $f); echo NFBS/masks/${i}mm/$g; done >> ${LibPath}/library.masks.${i}mm
done

#make intersection, union, and margin mask
cd $LibPath
echo Making segmentation masks...

#From the minc github
#/opt/minc-itk4/bin/mincmath -or `cat library.masks.1mm |xargs ` union_mask.mnc -clob
#/opt/minc-itk4/bin/mincmath -and `cat library.masks.1mm |xargs ` intersection_mask.mnc -clob
#/opt/minc-itk4/bin/minccalc -expr "if (A[0]) 0 else A[1]" intersection_mask.mnc union_mask.mnc margin_mask.mnc -clob

#from Bens code
/opt/minc-itk4/bin/mincmath -or $(cat library.masks.1mm|xargs) union_mask.mnc -clob
/opt/minc-itk4/bin/mincmath -and $(cat library.masks.1mm|xargs) intersection_mask.mnc -clob
/opt/minc-itk4/bin/mincmath -sub union_mask.mnc intersection_mask.mnc margin_mask.mnc -clob


duration=$SECONDS
echo "Time elapsed $(( $duration / 3600 )) hours, $(( $duration / 60 )) minutes, $(( $duration % 60 )) seconds"
