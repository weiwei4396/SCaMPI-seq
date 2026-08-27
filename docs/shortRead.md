---
icon: material/lightning-bolt
---

# SCaMPI-seq short read Tutorials
Welcome to the SCaMPI-seq short-read data analysis tutorials. This section provides practical examples and step-by-step instructions for processing and analyzing SCaMPI-seq short-read data.

欢迎来到 SCaMPI-seq 短读长数据分析教程。本部分提供详细的示例和分步操作指南，帮助您理解分析流程，并高效开展 SCaMPI-seq 短读长数据分析。

## SCaMPI-seq workflow

``` mermaid
%%{init: {'themeVariables': { 'fontSize': '20px' }}}%%
graph LR

  classDef input fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,color:black;
  classDef process fill:#fff9c4,stroke:#fbc02d,stroke-width:2px,color:black;
  classDef result fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px,color:black;

  A[Raw paired-end FASTQ.gz]:::input
  X[Barcode whitelist<br/>X / Y / Z]:::input
  R[Reference genome<br/>STAR index]:::input
  I[Fluorescence image<br/>Bright-field / H&E optional]:::input

  B[Valid-barcode reads<br/>Filtered FASTQ.gz]:::process
  C[Gene expression matrix]:::process
  E[Spatial coordinates]:::process
  D[AnnData .h5ad]:::result

  A -->|"Python"| B
  X -->|"Barcode matching"| B

  B -->|"STAR alignment<br/>Gene quantification"| C
  R -->|"Reference"| C

  I -->|"Image registration<br/>Coordinate inference"| E

  C -->|"Expression"| D
  E -->|"Spatial information"| D

  linkStyle 0,1 stroke:#ff9800,stroke-width:4px;
  linkStyle 2,3 stroke:#9c27b0,stroke-width:4px;
  linkStyle 4 stroke:#00897b,stroke-width:4px;
  linkStyle 5,6 stroke:#43a047,stroke-width:4px;
```

Short-read data for SCaMPI-seq were generated using the [MAGIC-seq](https://github.com/bioinfo-biols/MAGIC-seq) sequencing strategy, and the data analysis workflow largely followed that of MAGIC-seq. The workflow consists of three main steps：

* First, reads containing valid barcodes are identified and extracted from the raw sequencing data according to a predefined barcode whitelist.

* Next, the extracted reads are aligned to the reference genome to obtain gene expression information.

* Finally, the center coordinates of three peripheral spots on the chip are manually provided and used to infer the pixel coordinates of all spots on the chip, followed by image registration between the bright-field and stained images to complete the spatial coordinate mapping. The resulting spatial coordinates and gene expression information are then integrated and stored in an AnnData object for downstream analysis.

SCaMPI-seq 的短读长数据基于[MAGIC-seq](https://github.com/bioinfo-biols/MAGIC-seq)进行测序，其数据分析流程与 MAGIC-seq 基本一致。整个流程主要包括三个步骤：

* 步骤1. 根据预先提供的 barcode 清单，从原始测序数据中筛选并提取包含有效 barcode 的 reads；

* 步骤2. 将这些 reads 比对至参考基因组以获得基因表达信息；

* 步骤3. 手动提供三个芯片边缘 spot 的中心坐标，据此推算芯片上各 spot 对应的像素坐标，并通过明场图像与染色图像的配准进一步完成空间坐标映射。最终，将空间坐标信息与基因表达信息整合并存储于 AnnData 对象中，以供后续分析使用。



## SCaMPI-seq input files
To run SCaMPI-seq, you should provide:

* FASTQ (FASTQ.gz) should be processed into sorted SAM. [minimap2]

* Reference sequence in FASTA format.

* Optionally, you may provide a reference gene annotation in GTF format (recommend).

Before running SCaMPI-seq, the following input files should be prepared:

* Raw paired-end sequencing data: Paired-end FASTQ.gz files generated from the original sequencing run.

* Barcode files: For a nine-grid chip, three types of barcode files, corresponding to X, Y, and Z barcodes, should be provided. All three files follow the same format. For example, in barcodeX150.txt, the barcode whitelist format follows that defined in the MAGIC-seq study: the first column represents the indexed position of the barcode on the chip, and the second column contains the corresponding barcode sequence. The Y- and Z-barcode files use the same format.

* Reference genome and annotation files: A reference genome FASTA file and the corresponding genome annotation file are required. A STAR genome index should be generated in advance using the genomeGenerate function for downstream read alignment and expression quantification.

* Spatial imaging files: A fluorescence image showing the spatial distribution of spots is required. Bright-field and full-resolution H&E-stained images can also be optionally provided. The fluorescence image is used to visualize spot positions, while the bright-field and H&E images enable more accurate spatial registration and visualization of the spots relative to the corresponding tissue structures.

!!! note
    To ensure compatibility, the same version of STAR should be used for genome index construction and read alignment.

??? info "build STAR genome index"
    ```shell
    reference=/data/workdir/panw/reference/human/refdata-gex-GRCh38-2024-A/fasta/genome.fa
    gtf=/data/workdir/panw/reference/human/refdata-gex-GRCh38-2024-A/genes/genes.gtf
    outputFolder=./star2710b
    thread=16
    STAR --runThreadN $thread --runMode genomeGenerate --genomeDir $outputFolder --genomeFastaFiles $reference --sjdbGTFfile $gtf --sjdbOverhang 100 --genomeSAindexNbases 14 --genomeChrBinNbits 18 --genomeSAsparseD 3
    ```

运行 SCaMPI-seq 前，需要准备以下输入文件：

* 原始双端测序数据：提供原始测序生成的 paired-end FASTQ.gz 文件。

* Barcode 文件：对于九宫格芯片，需要分别提供 X、Y 和 Z 三类 barcode 文件。三类文件格式一致，例如 barcodeX150.txt。文件沿用 MAGIC-seq 文章中定义的 barcode 白名单格式，其中第一列表示 barcode 在芯片上的索引位置，第二列为对应的 barcode 序列。Y 和 Z 类 barcode 文件采用相同格式。

* 参考基因组与参考注释文件：需要提供参考基因组 FASTA 文件和基因组注释文件，并提前使用 STAR 的 genomeGenerate 功能构建基因组索引目录，供后续比对和表达定量使用。

* 空间成像文件：需要提供 spot 的荧光图像；此外，还可选提供明场图像和全分辨率 H&E 染色图像。荧光图像用于展示 spot 的空间位置，而明场图像和 H&E 图像可用于将 spot 与对应的组织结构进行更直观、准确的空间匹配和展示。

!!! note
    构建基因组索引和比对时的STAR版本需一致

??? info "STAR构建基因组索引"
    ```shell
    reference=/data/workdir/panw/reference/human/refdata-gex-GRCh38-2024-A/fasta/genome.fa
    gtf=/data/workdir/panw/reference/human/refdata-gex-GRCh38-2024-A/genes/genes.gtf
    outputFolder=./star2710b
    thread=16
    STAR --runThreadN $thread --runMode genomeGenerate --genomeDir $outputFolder --genomeFastaFiles $reference --sjdbGTFfile $gtf --sjdbOverhang 100 --genomeSAindexNbases 14 --genomeChrBinNbits 18 --genomeSAsparseD 3
    ```


## :book: SCaMPI-seq pipeline

* [x] Step1 Barcode and UMI extraction and correction

* For reads with a predefined structure, barcode and UMI sequences are extracted from their specified positions. This step supports correction of barcodes containing a 1-bp mismatch. Currently, the script only retains and corrects barcode sequences that differ from a valid barcode by a single nucleotide.Specifically, for each valid barcode, each of its eight nucleotide positions is individually substituted with one of A/G/C/T/N to generate all possible 1-bp mismatch candidates. A hash table containing the valid barcodes and their corresponding candidate sequences is then constructed. For each read, the extracted barcode is first checked for an exact match against the barcode whitelist. If no exact match is found, the barcode is further checked against the 1-bp mismatch candidates and, when applicable, corrected to the corresponding valid barcode.

* Barcode correction can also be disabled, in which case only reads containing barcodes that exactly match the whitelist are retained. Reads that neither exactly match a valid barcode nor satisfy the allowed mismatch criteria are discarded by default. Optionally, these filtered-out reads can be written to a separate output file.

* Finally, the retained FASTQ files are compressed in parallel using pigz and saved in .fastq.gz format.

* 对于具有固定结构的 reads，根据预先定义的位置提取 barcode 和 UMI 序列。该步骤支持对存在 1 bp mismatch 的 barcode 进行校正，脚本目前仅保留并校正与真实 barcode 相差 1 个碱基的序列。具体而言，对于每条真实 barcode 序列，将其 8 个碱基位置依次替换为 A/G/C/T/N 中的任意一种，从而生成所有可能的 1 bp mismatch 候选序列，并构建真实 barcode 及其候选序列的哈希表。对于每条 read，程序首先判断提取到的 barcode 是否与白名单中的真实 barcode 完全匹配；若不能完全匹配，则进一步判断其是否属于某个真实 barcode 的 1 bp mismatch 候选序列，并在满足条件时将其校正为对应的真实 barcode。

* 用户也可以选择关闭 barcode 校正功能，此时仅保留 barcode 与白名单完全匹配的 reads。对于既不能完全匹配、也不满足允许 mismatch 条件的 reads，默认直接丢弃；也可以通过可选参数将这些未通过筛选的 reads 单独输出。

* 处理完成后，保留的 FASTQ 文件使用 pigz 进行并行压缩，并输出为 .fastq.gz 文件。

```shell
# 1.extract_fastq1_barcode, only X and Y barcode
sample=CRR1158889
FASTQ1=/data/database/MAGIC-seq-NG/Olfb/CRR1158889_R1.fastq.gz
FASTQ2=/data/database/MAGIC-seq-NG/Olfb/CRR1158889_R2.fastq.gz
barcodeX=/data/database/MAGIC-seq-NG/Olfb/Mouse_Adult_Organ_T9_70_50um/Spatial_barcodeA70.txt
barcodeY=/data/database/MAGIC-seq-NG/Olfb/Mouse_Adult_Organ_T9_70_50um/Spatial_barcodeB70.txt
resultFolder=/data/database/MAGIC-seq-NG/Olfb/result
Extract=/data/database/MAGIC-seq-NG/Olfb/0_extract_fastq1_barcode.py

python $Extract \
	-i $FASTQ1 -I $FASTQ2 \
	--bcx $barcodeX --bcy $barcodeY \
	-m 2 -o $resultFolder 

cd $resultFolder
pigz -p 16 ${sample}_R1_trim.fastq
pigz -p 16 ${sample}_R2_trim.fastq
```

* The code above is designed for datasets containing two types of barcodes. For implementation details, please refer to [2Barcode](https://github.com/weiwei4396/SCaMPI-seq/blob/main/src/runSCaMPI2_step1.sh). For datasets containing three types of barcodes, please refer to [3Barcode](https://github.com/weiwei4396/SCaMPI-seq/blob/main/src/runSCaMPI3_step1.sh). 以上代码适用于包含两种 barcode 的情况，具体实现请参考[2Barcode](https://github.com/weiwei4396/SCaMPI-seq/blob/main/src/runSCaMPI2_step1.sh)，对于包含三种 barcode 的情况，请参考[3Barcode](https://github.com/weiwei4396/SCaMPI-seq/blob/main/src/runSCaMPI3_step1.sh)。

* Script parameters，脚本参数如下：

| Argument | Description | Required |
|---|---|---|
| `-i` | Raw paired-end read 1 | Yes |
| `-I` | Raw paired-end read 2 | Yes |
| `--bcx` | X barcode whitelist | Optional |
| `--bcy` | Y barcode whitelist | Optional |
| `--bcz` | Z barcode whitelist | Optional |
| `-m` | The number of barcode types: 2 or 3 | Yes |
| `-o` | output folder path | Yes |
| `--write_discarded` | Whether to output the discarded reads. By default, no output will be made. | Optional |
| `--no_barcode_correction` | Whether to correct the barcode, default correction is enabled | Optional |

```shell
python $Extract -i $FASTQ1 -I $FASTQ2 --bcx $barcodeX --bcy $barcodeY -m 2 -o $resultFolder --write_discarded --no_barcode_correction
```






* [x] Step2 Alignment to the reference genome 


使用STARsolo 将过滤后的reads比对到参考基因组。

上面的代码是针对的三个barcode的情况，两个barcode的情况同理，可以直接看脚本：BarcodeXY | BarcodeXYZ









