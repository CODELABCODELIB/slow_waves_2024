%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% data preperation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% path to raw data
processed_data_path = '/media/Storage/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG';
%% add folders to paths
addpath(genpath('/home/ruchella/slow_waves_2023'))
addpath(genpath('/home/ruchella/imports'))
addpath(genpath('/media/Storage/User_Specific_Data_Storage/ruchella/EEGsynclib_Mar_2022'))
addpath(genpath(processed_data_path), '-end')
%% Load EEG data
EEG = pop_loadset('/media/Storage/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/DS01/13_09_01_03_19.set');
options.bandpass_upper = 60;
options.bandpass_lower = 0.1;
EEG = gettechnicallycleanEEG(EEG,options.bandpass_upper,options.bandpass_lower);
%% select only smartphone data
% epoch around aligned tap
num_taps = size(find(EEG.Aligned.BS_to_tap.Phone == 1),2);
[EEG_taps] = add_events(EEG,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
[EEG_taps,indexes] = prepare_EEG_w_taps_only(EEG_taps);
%% run slow waves detection
orig_fs = 1000;
[twa_results]=twalldetectnew_TA_v2(EEG_taps.data,orig_fs,0);
%% refilter
options.bandpass_upper = 10;
options.bandpass_lower = 0.1; 
EEG = pop_loadset('/media/Storage/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG/DS01/13_09_01_03_19.set');
EEG_refilter = gettechnicallycleanEEG(EEG,options.bandpass_upper,options.bandpass_lower);
[EEG_refilter] = add_events(EEG_refilter,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
[EEG_refilter,indexes] = prepare_EEG_w_taps_only(EEG_refilter);
%%
chan=1; 
for wave = 1:10;
    figure;
    plot(twa_results.channels(chan).negzx{wave}:twa_results.channels(chan).wvend{wave},EEG_refilter.data(chan,twa_results.channels(chan).negzx{wave}:twa_results.channels(chan).wvend{wave})); 
    xline(twa_results.channels(chan).maxnegpk{wave}, 'r'); yline(twa_results.channels(chan).maxnegpkamp{wave}, 'r')
    xline(twa_results.channels(chan).maxpospk{wave}); yline(twa_results.channels(chan).maxpospkamp{wave})
end
%% plot erp 
% maxnegpk = cell2mat(twa_results.channels(1).maxnegpk);
% [EEG_taps_ch1] = add_events(EEG_taps,maxnegpk,length(maxnegpk),'maxnegpk');
% [EEG_epoched_ch1, indices] = pop_epoch(EEG_taps_ch1, {'maxnegpk'},[-2 2]);
chan=19;
[epochedvals] = getepocheddata(EEG_refilter.data(chan,:), cell2mat(twa_results.channels(chan).negzx), [-2000,2000]);
figure; plot(trimmean(epochedvals,20,1));
title(sprintf('E %d',chan))
%% plot density
twa_cell = struct2cell(twa_results.channels');
fields = fieldnames(twa_results.channels);
density = cellfun(@(chan) length(chan),twa_cell(find(strcmp(fields',"negzx")),:));
figure; topoplot(density(1:62),EEG_refilter.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
title('Density')
clim([round(min(density)),round(max(density))])
colormap autumn; colorbar;
%% plot density per min;
[densities] = density_per_dur(twa_results.channels,length(EEG_refilter.times)); 
density_min = [densities.med];
figure; topoplot(density_min(1:62),EEG_refilter.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
title('Density per min')
clim([round(min(density_min)),round(max(density_min))])
colormap autumn; colorbar;
%% plot p2p amp
[amp] = calculate_p2p_amplitude(twa_results.channels);
figure; topoplot(amp(1:60),EEG_refilter.chanlocs(1:60), 'electrodes', 'off', 'style', 'map');
title('Peak-to-peak amplitude')
clim([round(min(amp(1:60))),round(max(amp(1:60)))])
colormap autumn; colorbar;
%% plot downward slope
[dnslp] = calculate_slope(twa_results.channels, 'sel_field',"mxdnslp");
figure; topoplot(dnslp(1:60),EEG_refilter.chanlocs(1:60), 'electrodes', 'off', 'style', 'map');
title('Downward slope')
clim([round(min(dnslp(1:60))),round(max(dnslp(1:60)))])
colormap autumn; colorbar;
%% plot upward slope
[upslp] = calculate_slope(twa_results.channels, 'sel_field',"mxupslp");
figure; topoplot(upslp(1:60),EEG_refilter.chanlocs(1:60), 'electrodes', 'off', 'style', 'map');
title('Upward slope')
clim([round(min(upslp(1:60))),round(max(upslp(1:60)))])
colormap autumn; colorbar;
%% Timing of all the waves
% start_times = double([twa_results.channels(1).negzx{:}]);
start_times = [twa_results.channels.negzx];
start_times = cell2mat(start_times);
recording_times = zeros(1,length(EEG_refilter.times));
recording_times(start_times) = 1;
figure;
imagesc(recording_times);
colorbar parula;
%%
electrodes_to_reject = [1:62];
voltage_lower_threshold = -80; % In mV
voltage_upper_threshold = 80;
start_time = options.epoch_window_ms(1)/1000;
end_time = options.epoch_window_ms(2)/1000;
do_superpose = 0;
do_reject = 1;
try
    EEG_integrals_am = pop_eegthresh(EEG_integrals_am, 1, electrodes_to_reject, voltage_lower_threshold, voltage_upper_threshold, start_time, end_time, do_superpose, do_reject);
catch ME
    return
end