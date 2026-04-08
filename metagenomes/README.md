# file storage, naming convention, packages needed:
My metagenome files are stored in /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes/.
I have 4 folders (for the 4 samples sequenced on the NovaSeqX):
- DEM011 (file path /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes/DEM011/)
- DEM015
- DEM057
- DEM093

These are listed on the sample_list_crayfish_metagenomes.txt file to use in SLURM arrays.

Each sample folder has two files within, SAMPLE_1.fastq.gz and SAMPLE_2.fastq.gz (forward and reverse reads, respectively). For example, that would look like:
- /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes/DEM011/DEM011_1.fastq.qz and
- /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes/DEM011/DEM011_2.fastq.gz

| Sample Name  | _1.fq.gz size | _2.fq.gz size |
| ------------- | ------------- |------------- |
| DEM011  | 1.73 GB  | 1.70 GB |
| DEM015  | 4.48 GB  | 4.32 GB |
| DEM057  | 3.23 GB  | 2.82 GB |
| DEM093  | 2.65 GB  | 2.62 GB |

The raw sample reads were not initially QC-ed. DEM057 was also reported to have a poor quality library with short inserts.

## Packages used:
- 010: Fastp (https://github.com/OpenGene/fastp) was used for trimming and QCing. I downloaded it off of conda for use, but you can also get it from Github directly.
- 020: Metaspades used for assembly
- 030: Bowtie2 and samtools used to create coverage .txt files for metabat2 and maxbin2
- 031: Metabat2 and Maxbin2 used for binning
