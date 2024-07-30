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
%% assign taps to JID bins
[dt_dt,gridx,xi] = assign_tap2bin(res(pp).dt_dt_r);
time_to_next_sw_jid = cell(64,n_timelags);
time_to_prior_sw_jid  = cell(64,n_timelags);

for mins=1:n_timelags
    for chan=1:64;
        JID = cell(50,50);
        for sel_tap=1:size(time_to_next_sw,2)
            tmp = [time_to_next_sw{chan,:,mins}];
            JID{gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)} = cat(1,tmp(sel_tap),JID{gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)});
            time_to_next_sw_jid{chan,mins} = JID;
            tmp = [time_to_prior_sw{chan,:,mins}];
            JID{gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)} = cat(1,tmp(sel_tap),JID{gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)});
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
