#!/bin/bash

#SBATCH --job-name=LS_sw_amplitude
#SBATCH --output=LS_sw_amplitude.out
#SBATCH --error=LS_sw_amplitude.err
#SBATCH --mail-user="s3821013@vuw.leidenuniv.nl"
#SBATCH --mail-type="ALL"
#SBATCH --partition="cpu-long"
#SBATCH --time=2-0:00:00
#SBATCH --ntasks=1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=1

module load MATLAB/2023b
cd /home/s3821013
matlab -nosplash -nodesktop -r "addpath('/home/s3821013/eeglab2023.1'); addpath('/home/s3821013/pipeline2'); addpath(genpath('/home/s3821013/src')); data_path = '/home/s3821013/data_pi-ghosha2/erp_sw2_1_4'; addpath(data_path); eeglab nogui; plot_SWamplitude_timeseries(data_path, 1:62); exit"