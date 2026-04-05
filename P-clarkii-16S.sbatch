#!/bin/bash
#SBATCH -J qiime2-pclarkii
#SBATCH -A gts-ktk3-coda20
#SBATCH -n 8
#SBATCH --mem=100G
#SBATCH -t12:00:00
#SBATCH -q inferno
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o /storage/home/hcoda1/0/skapasi3/r-ktk3-0/P_clarkii/log/qiime2-pclarkii_out.16
#SBATCH -e /storage/home/hcoda1/0/skapasi3/r-ktk3-0/P_clarkii/log/qiime2-pclarkii_err.16

# Load conda/mamba environment
source /storage/home/hcoda1/0/skapasi3/miniconda3/etc/profile.d/conda.sh
cd /storage/home/hcoda1/0/skapasi3/r-ktk3-0/P_clarkii/1_rawdata/
conda activate qiime2-env

# Where qiime2-env is a conda environment with your desired version of QIIME2

# Flow of analysis:
#1. Log into PACE and setup the environment.
#2. Trim the primers out of the demultiplexed sequences (assumes you have uploaded files via manifest into demux-seqs.qza)

qiime cutadapt trim-paired 
--i-demultiplexed-sequences demux-seqs.qza \
--p-front-f CCTACGGGNGGCWGCAG \
--p-front-r GACTACHVGGGTATCTAATCC \
--p-discard-untrimmed \
--p-match-read-wildcards \
--p-match-adapter-wildcards \
--o-trimmed-sequences demux-trimmed-seqs.qza \
--verbose

# Primers are Klindworth Sequences

# Visualize demux-trimmed-seqs.qza so that you can find appropriate truncation parameters!
#3. Denoise using dada2

qiime dada2 denoise-paired 
--i-demultiplexed-seqs demux-trimmed-seqs.qza \
--p-trunc-len-f 240 \
--p-trunc-len-r 240 \
--o-table asv-table.qza \
--o-representative-sequences rep_seqs.qza \
--o-denoising-stats stats.qza \
--verbose

# Parameters based on demux-trimmed-seqs.qzv

#4. Learn more about how the stats of the denoising look like, as well as the sample and ASV frequencies
qiime metadata tabulate --m-input-file stats.qza --o-visualization stats.qzv

qiime feature-table summarize-plus \
--i-table asv-table.qza \
--m-metadata-file metadata.tsv \
--o-summary asv-table.qzv \
--o-sample-frequencies sample-frequencies.qza \
--o-feature-frequencies asv-frequencies.qza \
--verbose

#5. Map feature IDs to sequences
qiime feature-table tabulate-seqs \
--i-data rep-seqs.qza \
--m-metadata-file asv-frequencies.qza \
--o-visualization asv-seqs.qzv

#6. Narrow down features to those that are observed in at least 2 samples
qiime feature-table filter-features \
--i-table asv-table.qza \
--p-min-samples 2 \
--o-filtered-table asv-table-ms2.qza

qiime feature-table filter-seqs \
--i-data asv-seqs.qza \
--i-table asv-table-ms2.qza \
--o-filtered-data asv-seqs-ms2.qza

qiime feature-table summarize-plus \
--i-table asv-table-ms2.qza \
--m-metadata-file crayfish-metadata.tsv \
--o-summary asv-table-ms2.qzv \
--o-sample-frequencies sample-frequencies-ms2.qza \
--o-feature-frequencies asv-frequencies-ms2.qza

#7. Train classifier (download)
# First see what version of QIIME2 is running
# I used QIIME 2021.4, Silva 138 99% OTUs from 515F/806R region of sequences
# UUID: 9b9c290b-2297-4711-bafe-7cc603f3b990, SHA256: 5b08f1c272b16208830b2b712a682824b82671c8b6c5fe325ccd7feabfc498ba
# Sklearn version: 0.24.1
# Date Trained: 2021-05-07

wget -O the-classifier.qza https://data.qiime2.org/2021.4/common/silva-138-99-515-806-nb-classifier.qza

qiime feature-classifier classify-sklearn \
--i-classifier the-classifier.qza \
--i-reads asv-seqs-ms2.qza \
--o-classification taxonomy.qza

## constructing result collection ##
construct_result_collection () {
    mkdir $rc_name
    touch $rc_name.order
    for key in "${keys[@]}"; do
        echo $key >> $rc_name.order
    done
    for i in "${!keys[@]}"; do
        ln -s ../"${names[i]}" $rc_name"${keys[i]}"$ext
    done
}
##

rc_name=taxonomy-collection/
ext=.qza
keys=( Silva-13-8 )
names=( taxonomy.qza )
construct_result_collection

qiime feature-table tabulate-seqs \
--i-data asv-seqs-ms2.qza \
--i-taxonomy taxonomy-collection/ \
--m-metadata-file asv-frequencies-ms2.qza \
--o-visualization asv-seqs-ms2.qzv

#8. Make a phylogenetic tree
qiime fragment-insertion sepp \
--i-representative-sequences rep_seqs.qza \
--i-reference-database the-classifier.qza \
--o-tree tree.qza \
--o-placements tree_placements.qza \
--p-threads 1

#9. Select a rarefaction depth to standardize analysis
qiime diversity alpha-rarefaction \
--i-table asv-table.qza \
--m-metadata-file metadata.tsv \
--o-visualization alpha_rarefaction_curves.qzv \
--p-min-depth 10 \
--p-max-depth 4250

#10. Retrieve alpha and beta diversity outputs
qiime diversity core-metrics-phylogenetic \
--i-table asv-table.qza \
--i-phylogeny tree.qza \
--m-metadata-file metadata.tsv \
--p-sampling-depth 3000 \
--output-dir ./core-metrics-result

# 3000 would be arbitrary, the best depth from past step's alpha_rarefaction_curves.qzv

#11. Differential abundance analysis with LEfSe
qiime taxa collapse --i-table asv-table.qza --o-collapsed-table collapse.table.qza --p-level 6 --i-taxonomy taxonomy.qza
qiime feature-table relative-frequency --i-table collapse.table.qza --o-relative-frequency-table collapse.frequency.table.qza --output-dir collapse.frequency/
biom convert -i collapse.frequency.table.biom -o collapse.frequency.table.txt --header-key "taxonomy" --to-tsv

#Input output file into LEfSe!