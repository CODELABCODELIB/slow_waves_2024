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
addpath(genpath('/home/ruchella/TapDataAnalysis'))
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
unique_name = 'sw_test'; bandpass_lower = 1; bandpass_upper = 4; 
% run f using f2
f = @sw_detection; 
f2 = @call_f_all_p_parallel_sw; 
gen_checkpoints(unique_name,bandpass_lower,bandpass_upper, f,f2, 'processed_data_path',processed_data_path,'save_path_upper',save_path_upper, 'count',10);
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
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Slow waves to behavior %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sw_to_behavior',save_path_upper); 
data_path = sprintf('%s/erp_sw2_1_4',save_path_upper);
load_str='sw2'; data_name='A';
if ~exist(save_path, 'dir')
       mkdir(save_path); addpath(genpath(save_path))
end
f = @sw_to_behavior_all_pps;
run_f_checkpoints(data_path,load_str,data_name,f, 'save_path', save_path, 'aggregate_res', 1);
%% prepare the data
load(sprintf('%s/sw_to_behavior/EEG_res.mat',save_path_upper));
res = res(cellfun(@(x) isfield(x,'taps'),res));
res = cat(2,res{:});
%% %%%%%%%%%%%%%%%%%%%%%%%%% run NNMF SW JID %%%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sw_jid',save_path_upper);
if ~exist(save_path, 'dir')
    mkdir(save_path); addpath(genpath(save_path))
end
sw_jid_nnmf_main(res,'save_path',save_path, 'parameter', 'sw_jid')
%% cluster the nnmf maps across the population
stable_basis_all_pps = {};
for pp=1:41
    load(sprintf('%s/sw_jid/stable_basis_%d',save_path_upper,pp))
    load(sprintf('%s/sw_jid/reconstruct_%d',save_path_upper,pp))
    res(pp).stable_basis = stable_basis_all_chans;
    res(pp).reconstruct = reconstruct_all_chans;
end
% select the spatial maps
all_maps = cat(2,res.stable_basis);
[prototypes,labels,cluster_prototypes,cluster_labels] = cluster(all_maps);
%% %%%%%%%%%%%%%%%%%%%%%%%%% run NNMF SW rate %%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sw_rate_only_behaviour_nnmf',save_path_upper);
if ~exist(save_path, 'dir')
    mkdir(save_path); addpath(genpath(save_path))
end
sw_jid_nnmf_main(res,'save_path',save_path, 'parameter', 'sw_rate', 'log_transform',1)
%% %%%%%%%%%%%%%%%%%%%%%%%%% run NNMF SW rate %%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sw_rate_only_behaviour_nnmf',save_path_upper);
if ~exist(save_path, 'dir')
    mkdir(save_path); addpath(genpath(save_path))
end
sw_jid_nnmf_main(res,'save_path',save_path, 'parameter', 'sw_rate', 'log_transform',1)
%% %%%%%%%%%%%%%%%%%%%%%%%%% run NNMF SW amplitude %%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sw_amplitude_nnmf',save_path_upper);
if ~exist(save_path, 'dir')
    mkdir(save_path); addpath(genpath(save_path))
end
sw_jid_nnmf_main(res,'save_path',save_path, 'parameter', 'sw_amplitude', 'log_transform',0,'z_score',1)
%% plot NNMF results
subfolder = 'sw_rate_only_behaviour_nnmf';
for pp=1:41
    load(sprintf('%s/%s/stable_basis_%d',save_path_upper,subfolder,pp))
    load(sprintf('%s/%s/reconstruct_%d',save_path_upper,subfolder,pp))
    h = figure;
    best_k_overall = size(reconstruct_all_chans,2);
    tiledlayout(best_k_overall,2)
    for k=1:best_k_overall
        nexttile;
        plot_jid(reshape(reconstruct_all_chans(:,k),50,50))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Meta SW JID - Rank :%d',k))
        colorbar;
        set(gca, 'fontsize', 18)
        nexttile;
        topoplot(stable_basis_all_chans(1:62,k),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
        clim([0 1])
        colorbar;
        title(sprintf('Meta location - Rank :%d',k))
        set(gca, 'fontsize', 18)
    end
    sgtitle(sprintf('SW-JID NNMF Sub:%d',pp), 'fontsize', 18)
    saveas(h, sprintf('%s/nnmf/%s_pp_%d.svg',figures_save_path,subfolder,pp))
end