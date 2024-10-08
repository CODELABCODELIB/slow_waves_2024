#!/bin/bash

#SBATCH --job-name=LS_sw_pars
#SBATCH --output=LS_sw_pars.out
#SBATCH --error=LS_sw_pars.err
#SBATCH --mail-user="s3821013@vuw.leidenuniv.nl"
#SBATCH --mail-type="ALL"
#SBATCH --partition="cpu-long"
#SBATCH --time=2-0:00:00
#SBATCH --ntasks=1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=1

module load MATLAB/2023b
cd /home/s3821013
matlab -nosplash -nodesktop -r "addpath('/home/s3821013/eeglab2023.1'); addpath('/home/s3821013/fieldtrip-20240110'); addpath('/home/s3821013/pipeline'); addpath(genpath('/home/s3821013/src')); data_path = '/home/s3821013/data_pi-ghosha2/erp_sw2_1_4'; addpath(data_path); eeglab nogui; ft_defaults; load('chanlocs.mat'); ocular_channels = [63, 64]; [~, sw_pars] = sw_pars_per_participant_v2(data_path, chanlocs, 'exclude_channels', ocular_channels, 'interpolate_outliers', 1); save('sw_pars.mat', 'sw_pars'); aggregated_sw_pars = aggregate_sw_pars_v2(sw_pars, @mean, chanlocs, 'exclude_channels', ocular_channels); save('aggregated_sw_pars.mat', 'aggregated_sw_pars'); [t_vals, sign_ch] = condition_contrast_v2(sw_pars, chanlocs, 'exclude_channels', ocular_channels); t_test_results.t_vals = t_vals; t_test_results.sign_ch = sign_ch; save('t_test_results.mat', 't_test_results'); exit"