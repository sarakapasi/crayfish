#!/bin/bash
#SBATCH -J fastp
#SBATCH -A gts-ktk3-coda20
#SBATCH -n 4
#SBATCH --mem=64GB
#SBATCH -t 24:00:00
#SBATCH -q inferno
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=0-45%20
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_010-fastp_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_010-fastp_err.16

source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
conda activate binning_env #arbitrary conda environment
# conda install -c bioconda fastp - install fastp into conda environment before running the job

cd /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes/ #home directory with files

PARENT_DIR="/storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes"
# Get sample ID and directory for this array index from the sample file
SAMPLE_ID=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" sample_list_crayfish_metagenomes.txt)
SAMPLE_DIR="${PARENT_DIR}/${SAMPLE_ID}"

echo "Processing: $SAMPLE_DIR"

if [[ ! -d "$SAMPLE_DIR" ]]; then
    echo "ERROR: Sample directory not found: $SAMPLE_DIR"
    exit 1
fi

fastp -i "${SAMPLE_DIR}_1.fastq.gz" -I ${SAMPLE_DIR}_2.fastq.gz -o "${SAMPLE_DIR}-trimmed_1.fastq.gz" -O "${SAMPLE_DIR}-trimmed_2.fastq.gz" -h "${SAMPLE_DIR}_fastp.html" -j "${SAMPLE_DIR}_fastp.json" -w 4
