#!/bin/bash
#SBATCH -J binning
#SBATCH -A gts-ktk3-coda20
#SBATCH -n 8
#SBATCH --mem=100G
#SBATCH -t24:00:00
#SBATCH --cpus-per-task=10             
#SBATCH -q inferno
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=0-3%20
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_031-binning_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_031-binning_err.16

###############################################################################
# METABAT2 ANALYSIS PIPELINE
###############################################################################

source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
conda activate binning_env

PARENT_DIR="/storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes"
# Get sample ID and directory for this array index from the sample file
SAMPLE_ID=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" sample_list_crayfish_metagenomes.txt) #For example, DEM011
SAMPLE_DIR="${PARENT_DIR}/${SAMPLE_ID}" #For example, /3_metagenomes/DEM011

echo "Processing: $SAMPLE_DIR"
if [[ ! -d "$SAMPLE_DIR" ]]; then
    echo "ERROR: Sample directory not found: $SAMPLE_DIR"
    exit 1
fi

echo ""
echo "Step 1: Locating input files..."
echo "=========================================="
echo "  Parent directory: $PARENT_DIR"
echo "  Sample name: $SAMPLE_ID"

METASPADES_OUTPUT_DIR="${SAMPLE_DIR}/${SAMPLE_ID}_spades_abundance_analysis"
SPADES_DIR="${SAMPLE_DIR}/${SAMPLE_ID}_metaspades"

MAXBIN_BINS="${SAMPLE_DIR}/${SAMPLE_ID}_maxbin_bins"
METABAT_BINS="${SAMPLE_DIR}/${SAMPLE_ID}_metabat_bins"
CONTIGS_FILE="${SPADES_DIR}/contigs.fa"
COVERAGE_MX="${METASPADES_OUTPUT_DIR}/coverage_for_maxbin.txt"
COVERAGE_MB="${METASPADES_OUTPUT_DIR}/coverage_for_metabat.txt"

# Metabat2
mkdir -p "$METABAT_BINS" #made
metabat2 --inFile "${CONTIGS_FILE}" --outFile "${METABAT_BINS}/bin" --abdFile "${COVERAGE_MB}" --minContig 5000 --maxP 95 --minS 60 --maxEdges 200 --pTNF 0  --minCV 1.0 --minCVSum 1.0 --seed 0 --minClsSize 200000 > process_log_mb.txt

# Maxbin2
mkdir -p "$MAXBIN_BINS"
cd "$MAXBIN_BINS" || exit 0
echo "  Running Maxbin on contig file ..."
echo "$COVERAGE_MX" >> abund_list
run_MaxBin.pl -contig "${CONTIGS_FILE}" -out "${MAXBIN_BINS}/out" -abund_list abund_list -min_contig_length 5000 -max_iteration 50 -prob_threshold 0.5  -markerset 107 
gzip -cd out.marker_of_each_bin.tar.gz | tar -xf -

echo ""
echo "=========================================="
echo "Sample: $SAMPLE_NAME"
echo "End Time: $(date)"
echo ""
