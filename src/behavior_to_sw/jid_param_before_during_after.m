function [jid_delays] = jid_param_before_during_after(taps,refilter,f,dt_dt_r,options)
arguments 
    taps;
    refilter;
    f function_handle;
    dt_dt_r;
    options.n_timelags = [0:0.5:5];
end
n_timelags = [0:0.5:5];
jid_delays_before = cell(64,length(n_timelags));
jid_delays_after = cell(64,length(n_timelags));
count = 1;
% for mins=1:n_timelags
for mins=n_timelags
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
    [jid_delays_before(:,count),amp_per_triad_before,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_before,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
    [jid_delays_after(:,count),amp_per_triad_after,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_after,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
    count=count+1;
end
[jid_amp,amp_per_triad,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves,dt_dt_r, f, 'sel_field',"maxpospkamp");
jid_delays = cat(2,jid_delays_before,jid_amp,jid_delays_after);