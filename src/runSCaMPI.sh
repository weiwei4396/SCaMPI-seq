
sample=CRR1158889
FQ1=/data/database/MAGIC-seq-NG/Olfb/CRR1158889_R1.fastq.gz
FQ2=/data/database/MAGIC-seq-NG/Olfb/CRR1158889_R2.fastq.gz
barcodeX=/data/database/MAGIC-seq-NG/Olfb/Mouse_Adult_Organ_T9_70_50um/Spatial_barcodeA70.txt
barcodeY=/data/database/MAGIC-seq-NG/Olfb/Mouse_Adult_Organ_T9_70_50um/Spatial_barcodeB70.txt
resultLinker=/data/database/MAGIC-seq-NG/Olfb/result

getPY=/data/database/MAGIC-seq-NG/Olfb/0_extract_fastq1_barcode.py

python $getPY \
	-i $FQ1 -I $FQ2 \
	--bcx $barcodeX --bcy $barcodeY \
	-m 2 -o $resultLinker 

cd $resultLinker
pigz -p 16 ${sample}_R1_trim.fastq
pigz -p 16 ${sample}_R2_trim.fastq

