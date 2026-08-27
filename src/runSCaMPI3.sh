
FQ1=/data/database/MAGIC-seq-NG/E17-1/CRR1158992_R1.fastq.gz
FQ2=/data/database/MAGIC-seq-NG/E17-1/CRR1158992_R2.fastq.gz
barcodeX=/data/database/MAGIC-seq-NG/E17-1/Barcode-M9-150-E17.5/Spatial_barcodeA150.txt
barcodeY=/data/database/MAGIC-seq-NG/E17-1/Barcode-M9-150-E17.5/Spatial_barcodeB150.txt
barcodeZ=/data/database/MAGIC-seq-NG/E17-1/Barcode-M9-150-E17.5/Spatial_barcodeC18.txt
resultLinker=/data/database/MAGIC-seq-NG/E17-1/resultYihuan
getPY=/data/database/MAGIC-seq-NG/E17-1/script1_getBarcodeSR_magicseq_20260804.py

python $getPY \
	-i $FQ1 -I $FQ2 \
	--bcx $barcodeX --bcy $barcodeY --bcz $barcodeZ \
	-m 3 -o $resultLinker 

cd $resultLinker
pigz -p 16 CRR1158992_R1_trim.fastq
pigz -p 16 CRR1158992_R2_trim.fastq

