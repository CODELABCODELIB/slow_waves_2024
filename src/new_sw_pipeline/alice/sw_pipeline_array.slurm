#!/bin/bash

#SBATCH --job-name=sw_refined_ica
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err
#SBATCH --mail-user="s3821013@vuw.leidenuniv.nl"
#SBATCH --mail-type="END,FAIL"
#SBATCH --partition="cpu-short"
#SBATCH --time=0-4:00:00
#SBATCH --ntasks=1
#SBATCH --mem=48G
#SBATCH --cpus-per-task=4

# ---- Paths: edit these -------------------------------------------------------
EEGLAB_DIR=/home/s3821013/eeglab2023.1
CODE_DIR=/home/s3821013/sw_pipeline_alice              # where the zip was unpacked
export SW_INPUT_DIR=/data1/s3821013/CHANGE_ME           # root with the participant folders (.set/.fdt)
export SW_OUTPUT_DIR=/data1/s3821013/sw_refined_ica_rerun
# ------------------------------------------------------------------------------

PIPELINE_DIR=$CODE_DIR/new_sw_pipeline
ALICE_DIR=$CODE_DIR/alice

module load MATLAB/2023b
echo "Task $SLURM_ARRAY_TASK_ID of job $SLURM_ARRAY_JOB_ID on $HOSTNAME"

matlab -batch "maxNumCompThreads($SLURM_CPUS_PER_TASK); addpath('$EEGLAB_DIR'); eeglab nogui; addpath('$PIPELINE_DIR'); addpath('$ALICE_DIR'); run_sw_pipeline_alice"
