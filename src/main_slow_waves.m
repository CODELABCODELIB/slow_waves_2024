%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% data preperation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% path to raw data
processed_data_path = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG';
figures_save_path = '/home/ruchella/slow_waves_2023/figures';
save_path_upper = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/';
%% add folders to paths
addpath(genpath('/home/ruchella/slow_waves_2023'))
addpath(genpath('/home/ruchella/imports'))
addpath(genpath('/home/ruchella/NNMF/nnmf_pipeline_spams'))
addpath(genpath('/mnt/ZETA18/User_Specific_Data_Storage/ruchella/EEGsynclib_Mar_2022'))
addpath(genpath(processed_data_path), '-end')
%% Load EEG data
% EEG = pop_loadset('/media/Storage/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/DS01/13_09_01_03_19.set');
EEG = pop_loadset('/mnt/ZETA18/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/AT08/12_57_07_05_18.set');
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pre-processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% perform the sw detection on phone and movie data with checkpoints
% create folder to save the results
if ~exist(save_path_upper, 'dir'); mkdir(save_path_upper); end
% file naming
unique_name = 'sw2'; bandpass_lower = 1; bandpass_upper = 4; 
% run f using f2
f = @sw_detection; 
f2 = @call_f_all_p_parallel_sw; 
gen_checkpoints(unique_name,bandpass_lower,bandpass_upper, f,f2, 'processed_data_path',processed_data_path,'save_path_upper',save_path_upper, 'count',1);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Figure 4:JID-waves NNMF %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% JID-amplitudes
save_path = sprintf('%s/jid_amp',save_path_upper); 
data_path = sprintf('%s/erp_sw2_1_4',save_path_upper);
load_str='sw2'; data_name='A';
if ~exist(save_path, 'dir')
       mkdir(save_path); addpath(genpath(save_path))
end
f = @jid_waves_main;
run_f_checkpoints(data_path,load_str,data_name,f, 'save_path', save_path, 'aggregate_res', 1);
%% cluster the nnmf maps across the population
data_path = sprintf('%s/jid_amp',save_path_upper);
load(sprintf('%s/EEG_res.mat',data_path))
% remove the empty structs and concat all the participants
res = res(cellfun(@(x) isfield(x,'stable_basis_amp'),res));
res = cat(2,res{:});
% select the spatial maps
all_maps = cat(2,res.stable_basis_amp);
[prototypes,labels,cluster_prototypes,cluster_labels] = cluster(all_maps);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Figure 3:JID-waves NNMF with delays %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
f=@calculate_p2p_amplitude;
n_timelags = [0:0.5:10];
save_path = sprintf('%s/jid_amp_delay_nnmf_%d_to_%d',save_path_upper,min(n_timelags),max(n_timelags));
if ~exist(save_path, 'dir')
       mkdir(save_path); addpath(genpath(save_path))
end
jid_delay_nnmf_main(res,f, 'save_path',save_path,'n_timelags',n_timelags)