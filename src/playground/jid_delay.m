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
n_timelags = 5;
time_to_next_sw = cell(64,length(taps)-2,n_timelags);
time_to_prior_sw = cell(64,length(taps)-2,n_timelags);
for mins=1:n_timelags
    triad_lengths = nan(length(taps)-2,1);
    for chan=1:length(refilter.channels)
        slow_waves = [refilter.channels(chan).maxnegpk{:}];
        tmp = NaN;
        for triad_idx = 1:length(taps)-2
            triad = taps(triad_idx:triad_idx+2);            
            if mins == 1
                tmp = slow_waves(slow_waves > triad(end));
                if isempty(tmp); tmp(1)=triad(end); end
                time_to_next_sw{chan,triad_idx,mins} = tmp(mins) - triad(end);
                tmp = slow_waves(slow_waves < triad(1));
                if isempty(tmp) || mins >= length(tmp);
                    prior_idx = triad(1);
                else
                    prior_idx = tmp(end-mins);
                end
                time_to_prior_sw{chan,triad_idx,mins} =  triad(1)-prior_idx;
            else
                tmp = slow_waves(slow_waves > triad(end));
                if isempty(tmp) || mins >= length(tmp); 
                    next_idx = triad(end);
                    next_idx_2= triad(end); 
                else 
                    next_idx  = tmp(mins);
                    next_idx_2 =  tmp(mins-1);
                end
                
                time_to_next_sw{chan,triad_idx,mins} = next_idx - next_idx_2;
                tmp = slow_waves(slow_waves < triad(1));
                if isempty(tmp) || mins >= length(tmp);
                    prior_idx = triad(1);
                    prior_idx_2 = triad(1);
                else
                    prior_idx = tmp(end-mins);
                    prior_idx_2 = tmp(end-mins+1);
                end
                time_to_prior_sw{chan,triad_idx,mins} =  prior_idx_2-prior_idx;
            end          
        end
    end
end
% assign taps to JID bins
time_to_next_sw_jid = cell(64,n_timelags);
time_to_prior_sw_jid  = cell(64,n_timelags);
for mins=1:n_timelags
    for chan=1:64;
        for sel_tap=1:size(time_to_next_sw,2)
            tmp = [time_to_next_sw{chan,:,mins}];
            JID(gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)) = tmp(sel_tap);
            time_to_next_sw_jid{chan,mins} = JID;
            tmp = [time_to_prior_sw{chan,:,mins}];
            JID(gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)) = tmp(sel_tap);
            time_to_prior_sw_jid{chan,mins} = JID;
        end
    end
end
%% plot delays in JID form
figure;
tiledlayout(2,5)
log_time_to_next_sw = cellfun(@(x) log10(x),time_to_next_sw_jid,'UniformOutput',false);
log_time_to_prior_sw = cellfun(@(x) log10(x),time_to_prior_sw_jid,'UniformOutput',false);
x = [log_time_to_next_sw{:}]; 
p = [log_time_to_prior_sw{:}]; 
for mins=flip([1:5])
    nexttile;
    plot_jid(log_time_to_prior_sw{chan,mins})
    clim(quantile(p(isfinite(p)),[0.1 0.95],'all'))
    colorbar;
    title(sprintf('%d',mins))
end
for mins=1:n_timelags
    nexttile;
    plot_jid(log_time_to_next_sw{chan,mins})
    clim(quantile(x(isfinite(x)),[0.1 0.95],'all'))
    colorbar;
    title(sprintf('%d',mins))
end
%% plot delays in JID form
reshaped_timelagged = cellfun(@(x) reshape(x,[2500,1]),time_to_next_sw,'UniformOutput',false);
