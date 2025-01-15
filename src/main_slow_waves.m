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
unique_name = 'sws_2025'; bandpass_lower = 1; bandpass_upper = 4; 
% run f using f2
f = @get_eeg_structs; 
f2 = @call_f_all_p_parallel_sw; 
gen_checkpoints(unique_name,bandpass_lower,bandpass_upper, f,f2, 'processed_data_path',processed_data_path,'save_path_upper',save_path_upper, 'count',1);
%% perform slow wave detection on EEG checkpoints
save_path = sprintf('%s/sws_2025_1_4',save_path_upper); 
data_path = sprintf('%s/erp_sws_2025_1_4',save_path_upper);
load_str='sws'; data_name='A';
if ~exist(save_path, 'dir')
       mkdir(save_path); addpath(genpath(save_path))
end
f = @sw_detection_main;
run_f_checkpoints(data_path,load_str,data_name,f, 'save_path', save_path, 'aggregate_res', 0,'start_range',1,'end_range',5);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Slow waves to behavior %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sws_2025_features',save_path_upper); 
data_path = sprintf('%s/sws_2025_1_4',save_path_upper);
load_str='sws'; data_name='res';
if ~exist(save_path, 'dir')
       mkdir(save_path); addpath(genpath(save_path))
end
f = @sw_to_behavior_all_pps;
run_f_checkpoints(data_path,load_str,data_name,f, 'save_path', save_path, 'aggregate_res', 1);
%% slow wave shapes
save_path = sprintf('%s/sws_2025_erp',save_path_upper); 
data_path = sprintf('%s/sws_2025_1_4',save_path_upper);
load_str='sws'; data_name='res';
if ~exist(save_path, 'dir')
       mkdir(save_path); addpath(genpath(save_path))
end
f = @sw_erp;
run_f_checkpoints(data_path,load_str,data_name,f, 'save_path', save_path, 'aggregate_res', 1,'start_range',1);
%% prepare the data
load(sprintf('%s/sws_2025_features/EEG_res.mat',save_path_upper));
res = res(cellfun(@(x) isfield(x,'taps'),res));
res = cat(2,res{:});
[~,idx_unique] = unique(cellfun(@(x) x(87:90),{res.pp},'UniformOutput',false));
%% %%%%%%%%%%%%%%%%%%%%%%%%% run NNMF SW JID %%%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sw_jid_phone',save_path_upper);
if ~exist(save_path, 'dir')
    mkdir(save_path); addpath(genpath(save_path))
end
sw_jid_nnmf_main(res,'save_path',save_path, 'parameter', 'sw_jid')
% %%%%%%%%%%%%%%%%%%%%% run NNMF SW JID movie %%%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/sw_jid_movie',save_path_upper);
if ~exist(save_path, 'dir')
    mkdir(save_path); addpath(genpath(save_path))
end
sw_jid_nnmf_main(res,'save_path',save_path, 'parameter', 'sw_jid_movie')
%% prepare data for clustering
parameters = {'movie', 'phone'};
for i=1:length(parameters)
    parameter = parameters{i};
    stable_basis_all_pps = {};
    for pp=1:41
        load(sprintf('%s/sw_jid_%s/stable_basis_%d',save_path_upper,parameter,pp))
        load(sprintf('%s/sw_jid_%s/reconstruct_%d',save_path_upper,parameter,pp))
        res(pp).(sprintf('stable_basis_%s',parameter)) = stable_basis_all_chans;
        res(pp).(sprintf('reconstruct_%s',parameter)) = reconstruct_all_chans;
    end
end
% select the spatial maps
all_maps_movie = cat(2,res.stable_basis_movie);
all_jids_movie = cat(2,res.reconstruct_movie);
all_maps_phone = cat(2,res.stable_basis_phone);
all_jids_phone = cat(2,res.reconstruct_phone);
%% Cluster the nnmf jids 
%% Find optimal K: kmeans elbow method
figure;
tiledlayout(2,2)
for i=1:length(parameters)
    kmeans_error = zeros(1,10);
    for n_clus=1:10
        [~,~,~,~,kmeans_error(n_clus)] = cluster(all_jids', 'modkmeans', 0, 'n_clus',n_clus);
    end
    nexttile;
    plot(kmeans_error)
    title(sprintf('k means error %s',parameter))
    evaluation = evalclusters(all_jids',"kmeans","silhouette","KList",1:10);
    nexttile;
    plot(evaluation)
    title(sprintf('sillhoutte %s',parameter))
end

%% cluster the nnmf maps across the population
% [prototypes,labels,cluster_prototypes,cluster_labels] = cluster(all_maps);
% save(sprintf('%s/sw_jid_%s/labels.mat',save_path_upper,parameter),'labels')
% save(sprintf('%s/sw_jid_%s/prototypes.mat',save_path_upper,parameter),'prototypes')
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