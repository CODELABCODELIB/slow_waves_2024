%%
refilter = A{1,2}{1,4};
[dt_dt_r,~] = calculate_ITI_K_ITI_K1(taps, 'shuffle', 0); 
[dt_dt,gridx,xi] = assign_tap2bin(dt_dt_r);
%%
n_timelags = 5;
jid_delays_before = cell(64,n_timelags);
jid_delays_after = cell(64,n_timelags);
for mins=1:n_timelags
    time_bin = mins*60*1000;
    selected_waves = cell(64,length(taps)-2);
    selected_waves_before = cell(64,length(taps)-2);
    selected_waves_after = cell(64,length(taps)-2);
    triad_lengths = nan(length(taps)-2,1);
    for chan=1:length(refilter.channels)
        slow_waves = [refilter.channels(chan).maxnegpk{:}];
        for triad_idx = 1:length(taps)-2
            triad = taps(triad_idx:triad_idx+2);
            tmp = slow_waves >= triad(1) & slow_waves <= triad(end);
            tmp_before = slow_waves >= triad(1)-(time_bin*mins)  & slow_waves <= triad(1)-(time_bin*(mins-1));
            tmp_after = slow_waves >= triad(end)+(time_bin*(mins-1)) & slow_waves <= triad(end)+(time_bin*mins);
            selected_waves{chan,triad_idx} = tmp;
            selected_waves_before{chan,triad_idx} = tmp_before;
            selected_waves_after{chan,triad_idx} = tmp_after;
            triad_lengths(triad_idx,1) = triad(end)-triad(1);
        end
    end
    [jid_delays_before(:,mins),amp_per_triad_before,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_before,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
    [jid_delays_after(:,mins),amp_per_triad_after,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_after,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
end
[jid_amp,amp_per_triad,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves,dt_dt_r, f, 'sel_field',"maxpospkamp");
jid_delays = cat(2,jid_delays_before,jid_amp,jid_delays_after);
%% perform nnmf
for chan=1:64
    [reshaped_jid_amp,kept_bins] = prepare_sw_data_for_nnmf(jid_delays(chan,:)','zscore', 0, 'threshold',0.75, 'log_transform',0);
    if ~isempty(reshaped_jid_amp)
        [reconstruct,stable_basis] = perform_sw_param_nnmf(reshaped_jid_amp,kept_bins, 'repetitions_cv',50);
    end
    h = figure;
    best_k_overall = size(reconstruct,2);
    tiledlayout(best_k_overall,2)
    for k=1:best_k_overall
        nexttile;
        plot_jid(reshape(reconstruct(:,k),50,50))
        colorbar;
        set(gca, 'fontsize', 18)
        nexttile;
        plot([-5:5],stable_basis(:,k))
        axis square;
        set(gca, 'fontsize', 18)
    end
    title(sprintf('Electrode %d',chan))
end
%%
EEG = gettechnicallycleanEEG_sw(EEG, [],[]); 
options.remove_EEG = 0;
[data,EEG_ds] = sw_detection(EEG, 'AT08',options);
%%
selected_EEG = cell(64,length(taps)-2);
selected_waves = cell(64,length(taps)-2);
time_bin = mins*60*1000;
triad_lengths = nan(length(taps)-2,1);
for chan=1:length(refilter.channels)
    slow_waves = [refilter.channels(chan).maxnegpk{:}];
    for triad_idx = 1:length(taps)-2
        triad = taps(triad_idx:triad_idx+2);
        tmp = EEG_ds.times >= triad(1) & EEG_ds.times <= triad(end);
        selected_EEG{chan,triad_idx} = EEG_ds.data(chan,tmp);
        

        tmp_sw_all = slow_waves(slow_waves >= triad(1) & slow_waves <= triad(end));
        sel_times = EEG_ds.times(EEG_ds.times >= triad(1) & EEG_ds.times <= triad(end));
        tmp_sw_idxs = nan(length(tmp_sw_all),1);
        tmp_sw = zeros(size(tmp));
        for sw=1:length(tmp_sw_all)
            [~,tmp_sw_idxs(sw)] = min(abs(sel_times-tmp_sw_all(sw)));
            tmp_sw(tmp_sw_idxs(sw)) = 1;
        end
        selected_waves{chan,triad_idx} = tmp_sw;
    end
end
%%
% [dt_dt,gridx,xi] = assign_tap2bin(dt_dt_r);
jid_eeg = assign_input_to_bin(taps,selected_EEG,selected_waves);
jid_sw = assign_input_to_bin(taps,selected_waves);
%%
    % [jid_delays_before(:,mins),amp_per_triad_before,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_before,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
    % [jid_delays_after(:,mins),amp_per_triad_after,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_after,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
% end
% [jid_amp,amp_per_triad,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves,dt_dt_r, f, 'sel_field',"maxpospkamp");
% jid_delays = cat(2,jid_delays_before,jid_amp,jid_delays_after);
%% 
% for i=1:100
%     if sum(selected_waves{1,i})
%         figure; plot(selected_EEG{1,i}); yyaxis right; plot(selected_waves{1,i});
%     end
% end