---
icon: material/lightning-bolt
---

# SCaMPI-seq short read Tutorials
Welcome to the SCaMPI-seq short-read data analysis tutorials. This section provides practical examples and step-by-step instructions for processing and analyzing SCaMPI-seq short-read data.

欢迎来到 SCaMPI-seq 短读长数据分析教程。本部分提供详细的示例和分步操作指南，帮助您理解分析流程，并高效开展 SCaMPI-seq 短读长数据分析。

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

* 首先，根据预先提供的 barcode 清单，从原始测序数据中筛选并提取包含有效 barcode 的 reads；

* 其次，将这些 reads 比对至参考基因组以获得基因表达信息；

* 最后，手动提供三个芯片边缘 spot 的中心坐标，据此推算芯片上各 spot 对应的像素坐标，并通过明场图像与染色图像的配准进一步完成空间坐标映射。最终，将空间坐标信息与基因表达信息整合并存储于 AnnData 对象中，以供后续分析使用。



## SCaMPI-seq short read input files
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
    To ensure compatibility, the same version of STAR should be used for genome index construction and read alignment. 构建基因组索引和比对时的STAR版本需一致

??? info "build STAR genome index / STAR构建基因组索引"
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



## :book: SCaMPI-seq short read pipeline

* [x] Step1 Extract the valid barcode 提取有效barcode

```shell

```

!!! note
    The mapping **SAM files** need to be **sorted** by samtools before running BroCOLI.

??? info "Noisy cDNA data recommended parameter"
    For **noisy 1D cDNA Nanopore data** the developer of Minimap2 suggests adding **-k 14** and **-w 4**:
    ```shell
    minimap2 -ax splice -ub -k14 -w 4 --secondary=no -t 20 ref.fasta raw.fastq.gz > raw.sam
    ```



* [x] Step2 Transcript identification and quantification

* For a single SAM file, use the -s parameter to specify its absolute path **(i)**.
* For multiple files, set the -s parameter to the directory containing the sorted SAM files **(ii)**. Alternatively, you can provide a TXT/TSV file listing the absolute path to each input SAM file on a separate line. The output order will correspond to the order listed in the file **(iii)**.






