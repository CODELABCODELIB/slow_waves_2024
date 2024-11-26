#!/bin/bash

#SBATCH --job-name=LS_sw_binning
#SBATCH --output=LS_sw_binning.out
#SBATCH --error=LS_sw_binning.err
#SBATCH --mail-user="s3821013@vuw.leidenuniv.nl"
#SBATCH --mail-type="ALL"
#SBATCH --partition="cpu-short"
#SBATCH --time=0-4:00:00
#SBATCH --ntasks=1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=1

module load MATLAB/2023b
cd /home/s3821013
matlab -nosplash -nodesktop -r "addpath('/home/s3821013/eeglab2023.1'); addpath('/home/s3821013/pipeline3'); addpath(genpath('/home/s3821013/src')); data_path = '/data1/s3821013'; addpath(data_path); eeglab nogui; plot_binned_timeseries(data_path, 60, 'sw_par', 'both', 'use_summary_file', true); exit"