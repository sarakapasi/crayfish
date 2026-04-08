#!/bin/bash
#SBATCH -J coverage
#SBATCH -A gts-ktk3-coda20
#SBATCH -n 4
#SBATCH --mem=100GB
#SBATCH -t 24:00:00
#SBATCH -q inferno
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --array=0-3%20
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_030-coverage_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/log/0408_030-coverage_err.16

source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
conda activate binning_env #arbitrary conda environment with metabat and maxbin

cd /storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes/ #home directory with files

PARENT_DIR="/storage/home/hcoda1/0/skapasi3/r-ktk3-0/FishData/3_metagenomes"
# Get sample ID and directory for this array index from the sample file
SAMPLE_ID=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" sample_list_crayfish_metagenomes.txt) #For example, DEM011
SAMPLE_DIR="${PARENT_DIR}/${SAMPLE_ID}" #For example, /3_metagenomes/DEM011/

echo "Processing: $SAMPLE_DIR"
if [[ ! -d "$SAMPLE_DIR" ]]; then
    echo "ERROR: Sample directory not found: $SAMPLE_DIR"
    exit 1
fi

#We will be binning with Maxbin2 and MetaBAT2 - both require coverage files to run.

# Output directory
OUTPUT_DIR="${SAMPLE_DIR}/${SAMPLE_ID}_spades_abundance_analysis"
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"
# Number of threads (match --cpus-per-task)
THREADS=16

echo ""
echo "Step 1: Identifying input files..."
echo "=========================================="
echo "  Parent directory: $PARENT_DIR"
echo "  Sample name: $SAMPLE_ID"

SPADES_DIR="${SAMPLE_DIR}/${SAMPLE_ID}_metaspades"
CONTIGS="${SPADES_DIR}/contigs.fa"
R1="${SAMPLE_DIR}/${SAMPLE_ID}-trimmed_1.fastq.gz"
R2="${SAMPLE_DIR}/${SAMPLE_ID}-trimmed_2.fastq.gz"

echo ""
echo "Step 2: Building Bowtie2 index..."
echo "=========================================="
bowtie2-build --threads $THREADS "$CONTIGS" bowtie_contigs.fasta

echo ""
echo "Aligning reads to contigs..."
echo "=========================================="
bowtie2 -p $THREADS \
    -x bowtie_contigs.fasta \
    -1 "$R1" \
    -2 "$R2" \
    -S contigs_vs_reads.sam \
    2> bowtie2_alignment.log

echo ""
echo "Converting SAM to BAM and sorting..."
echo "=========================================="
samtools view -S --threads $THREADS -b contigs_vs_reads.sam > contigs_vs_reads.bam
samtools sort --threads $THREADS contigs_vs_reads.bam -o contigs_vs_reads.sorted.bam
samtools index contigs_vs_reads.sorted.bam
rm contigs_vs_reads.sam contigs_vs_reads.bam

echo ""
echo "Step 5: Generating depth/coverage files..."
echo "=========================================="
jgi_summarize_bam_contig_depths --outputDepth coverage_for_metabat.txt contigs_vs_reads.sorted.bam

# Create coverage file for MaxBin2
cut -f1,3 coverage_for_metabat.txt | sed '1d' > coverage_for_maxbin.txt

echo ""
echo "=========================================="
echo "Sample: $SAMPLE_ID"
echo "Output directory: $OUTPUT_DIR"
echo "End Time: $(date)"
echo ""
echo "Output files generated:"
echo "  - bowtie_contigs.fasta.* (Bowtie2 index files)"
echo "  - contigs_vs_reads.sorted.bam (sorted BAM file)"
echo "  - contigs_vs_reads.sorted.bam.bai (BAM index)"
echo "  - coverage_for_metabat.txt (MetaBAT2 coverage)"
echo "  - coverage_for_maxbin.txt (MaxBin2 coverage)"
echo "=========================================="
