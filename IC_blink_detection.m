# Open a terminal 
```
cd matlab_2024a/bin
./matlab
```

# Running the blink detection algorithm on the EEG data.
```
%% path to raw data
processed_data_path = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG';
figures_save_path = '/home/ruchella/slow_waves_2023/figures';
save_path_upper = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/';
%% add folders to paths
addpath(genpath('/home/ruchella/slow_waves_2023_original'))
addpath(genpath('/home/ruchella/imports'))
addpath(genpath('/home/ruchella/TapDataAnalysis'))
addpath(genpath('/home/ruchella/NNMF/nnmf_pipeline_spams'))
addpath(genpath('/mnt/ZETA18/User_Specific_Data_Storage/ruchella/EEGsynclib_Mar_2022'))
addpath(genpath(processed_data_path), '-end') 
EEG = pop_loadset('/mnt/ZETA18/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/AT08/12_57_07_05_18.set');
run_opticat_training_sw('/mnt/ZETA18/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/AT08', 'start_idx', 1, 'end_idx', 1)
```