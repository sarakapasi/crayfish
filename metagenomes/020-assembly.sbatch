#!/bin/bash
#SBATCH -J assembly
#SBATCH -A gts-ktk3-coda20
#SBATCH -n 4
#SBATCH --mem=64GB
#SBATCH -t 24:00:00
#SBATCH -q inferno
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=0-45%20
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_020-assembly_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_020-assembly_err.16

source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
conda activate spades_env #arbitrary conda environment with metaspades

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

cd "$SAMPLE_DIR"

R1="${SAMPLE_ID}-trimmed_1.fastq.gz"
R2="${SAMPLE_ID}-trimmed_2.fastq.gz"

echo "Assembling sample: $SAMPLE_ID"
metaspades.py -1 "$R1" -2 "$R2" -o "${SAMPLE_ID}_metaspades"
