#!/bin/bash
# This script performs all processing steps + visualization of the extracted wave parameters on the movie EEG data.

#SBATCH --job-name=test_LS
#SBATCH --output=test_LS.out
#SBATCH --error=test_LS.err
#SBATCH --mail-user="s3821013@vuw.leidenuniv.nl"
#SBATCH --mail-type="ALL"
#SBATCH --partition="cpu-short"
#SBATCH --time=2:00:00
#SBATCH --ntasks=1
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
 
module load MATLAB/2023b
cd /home/s3821013
matlab -nosplash -nodesktop -r "addpath(genpath('.')); eeglab nogui; EEG = pop_loadset('filename', '12_57_07_05_18.set', 'filepath', '/data1/s3821013/local_sleep/AT08'); processed_EEG = test_processing4(EEG); results = twalldetectnew_TA_v2(processed_EEG.Movie.data, 1000, 0); top10_filtered_results = filter_results(results); save('top10_filtered_results.mat', 'top10_filtered_results'); wave_pars = compute_wave_pars(top10_filtered_results); visualize_wave_pars(wave_pars); exit"