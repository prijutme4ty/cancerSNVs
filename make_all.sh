#!/bin/bash
cd "$(dirname "$0")"

export RESULTS_FOLDER=./results
export SEQ_FOLDER=${RESULTS_FOLDER}/sequences
export SNV_FOLDER=${RESULTS_FOLDER}/SNVs
export CHUNK_FOLDER=${RESULTS_FOLDER}/sequence_chunks
export SITES_FOLDER=${RESULTS_FOLDER}/sites
export FITTING_FOLDER=${RESULTS_FOLDER}/fitted_sites
export MOTIF_STATISTICS_FOLDER=${RESULTS_FOLDER}/motif_statistics

# Prepare marked up SNVs and sequences.
# Generate random sequences.
# Split files into chunks for running computations in parallel.
# Estimated time is about 40 min to complete preparations
./preparations.sh

# ATTENTION! This command will run lots of background java workers.
# This step can take several days (it took about 1.5 days using 8 cores).
# If possible, put chunks on different machines so that workers run on several # cores and fix script so that it run only chunks on a current machine.
# In that case one also need to defer concatenating results and do it manually
# after joining processed chunks from all machines.
# By default we use 4 workers (for 4 cores), but it's easily configurable.
# If necessary one also can provide JVM options for PerfectosAPE run in a file ./prepare_sequences_for_perfectosape_run.sh
# For example it is worth to allow JVM to take up to 1-2Gb RAM (note, each worker will consume that much)
${CHUNK_FOLDER}/run_perfectosape_multithread.sh

# Separate sites by contexts. Perform random sites fitting. Extract motif statistics slices.
./filtering_and_fitting.sh

# Aggregate motif statistics slices and find motifs of interest
./aggregate_motifs_statistics.sh
