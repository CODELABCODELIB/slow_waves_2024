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
EEG = pop_loadset('/media/Storage/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/DS01/13_09_01_03_19.set');
EEG = pop_loadset('/media/Storage/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/AT08/12_57_07_05_18.set');
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% JID-waves %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save_path = sprintf('%s/jid_amp',save_path_upper); 
data_path = 
load_str='sw2'; data_name='A';
if ~exist(save_path, 'dir')
       mkdir(save_path); addpath(genpath(save_path))
end
f = @jid_waves_main;
run_f_checkpoints(data_path,load_str,data_name,f, 'save_path', save_path, 'aggregate_res', 1);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% JID-waves %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[taps] = find_taps(EEG, indexes); % tap indexes
[dt_dt_r,~] = calculate_ITI_K_ITI_K1(taps, 'shuffle', 0); 
%% identify waves occuring during triads
selected_waves = cell(64,length(taps)-2);
triad_lengths = nan(length(taps)-2,1);
for chan=1:length(refilter.channels)
    slow_waves = [refilter.channels(chan).maxnegpk{:}];
    for triad_idx = 1:length(taps)-2
        triad = taps(triad_idx:triad_idx+2);
        tmp = slow_waves>triad(1) & slow_waves<triad(end);
        selected_waves{chan,triad_idx} = tmp;
        triad_lengths(triad_idx,1) = triad(end)-triad(1);
    end
end
%%
selected_waves = cell(64,length(taps)-2);
triad_lengths = nan(length(taps)-2,1);
for chan=1:length(refilter.channels)
    slow_waves = [refilter.channels(chan).maxnegpk{:}];
    for triad_idx = 1:length(taps)-2
        triad = taps(triad_idx:triad_idx+2);
        tmp = slow_waves>triad(1) & slow_waves<triad(end);
        selected_waves{chan,triad_idx} = tmp;
        triad_lengths(triad_idx,1) = triad(end)-triad(1);
        if isempty(jid_microstates{gridx == dt_dt(triad_idx,3),gridx == dt_dt(triad_idx,4)})
            jid_microstates{gridx == dt_dt(triad_idx,3),gridx == dt_dt(triad_idx,4)} = {mstate_sequence};
            % if it is occupied concat the new sequence to existing one(s)
        else
            jid_microstates{gridx == dt_dt(triad_idx,3),gridx == dt_dt(triad_idx,4)} = cat(1,jid_microstates{gridx == dt_dt(triad_idx,3),gridx == dt_dt(triad_idx,4)},{mstate_sequence});
        end
    end
end
for triad_idx = 1:length(taps)-2
    triad = taps(triad_idx:triad_idx+2); % triad indexes
    % select microstate sequences during the triad
    mstate_sequence = microstates(triad(1):triad(3));
    % check if the bin is occupied already if not add the sequences

end
%% upward slopes JID
f = @calculate_slope;
[jid_upslp,upslp_per_triad] = jid_per_param(refilter.channels,selected_waves,dt_dt_r, f, 'sel_field',"mxupslp");
%% downward slopes JID
f = @calculate_slope;
[jid_dnslp,dnslp_per_triad] = jid_per_param(refilter.channels,selected_waves,dt_dt_r, f, 'sel_field',"mxdnslp");
%% density JID
[jid_density,density_per_triad] = jid_per_param(refilter.channels,selected_waves,dt_dt_r, [], triad_lengths);
%% NNMF density
[reshaped_jid_density,kept_bins] = prepare_sw_data_for_nnmf(jid_density,'threshold',0, 'log_transform',0);
%%
if ~isempty(reshaped_jid_density)
    [reconstruct,stable_basis] = perform_sw_param_nnmf(reshaped_jid_density,kept_bins, 'repetitions_cv',2);
end
%% amplitude JID
f = @calculate_p2p_amplitude;
[jid_amp,amp_per_triad,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves,dt_dt_r, f, 'sel_field',"maxpospkamp");
%% NNMFamp
[reshaped_jid_amp,kept_bins] = prepare_sw_data_for_nnmf(jid_amp,'zscore', 1, 'threshold',0.75, 'log_transform',0);
if ~isempty(reshaped_jid_amp)
    [reconstruct,stable_basis] = perform_sw_param_nnmf(reshaped_jid_amp,kept_bins, 'repetitions_cv',50);
end
%%
