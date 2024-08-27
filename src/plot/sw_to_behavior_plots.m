%% plot SW jids
for pp=1:1
    h = figure;
    tiledlayout(8,8, 'TileSpacing','none')
    % estimate the SW jid per channel
    for chan=1:62
        jid = taps2JID([res(pp).refilter.channels(chan).negzx{:}]);
        nexttile;
        plot_jid(jid);
        clim([0,0.6])
        % set(gca, 'visible','off')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
    end
    sgtitle(sprintf('SW JID - Sub %d',pp))
    saveas(h, sprintf('%s/sw_to_behavior/jid_sw_pp_%d.svg',figures_save_path,pp))
end
%% plot SW latency
for pp=1:size(res,2)
    taps = res(pp).taps;
    max_all = max(cell2mat(cellfun(@(x) length(x),{res(pp).refilter.channels.negzx},'UniformOutput',false)));
    next_tap = cellfun(@(x) NaN, num2cell(ones(64,max_all-2)), 'UniformOutput', false);
    for chan=1:length(res(pp).refilter.channels)
        slow_waves = [res(pp).refilter.channels(chan).negzx{:}];
        for slow_waves_triad_idx = 1:length(slow_waves)-2
            triad = slow_waves(slow_waves_triad_idx:slow_waves_triad_idx+2);
            tmp = taps(taps > triad(end));
            if ~isempty(tmp)
                next_tap{chan,slow_waves_triad_idx} = tmp(1)-triad(end);
            end
        end
    end
    res(pp).latency = next_tap;
end
%%
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        sw_to_behavior_latency = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).latency);
        pooled = cellfun(@(x) median(x),sw_to_behavior_latency{chan},'UniformOutput', 0);
        plot_jid(log10(reshape([pooled{:}],50,50)+ 0.00000001));
        clim([quantile(log10([pooled{:}]),[0.10, 0.90])])
        colorbar;
        set(gca, 'FontSize',10)
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
    end
    sgtitle(sprintf('Time to next tap (Log10[ms])- Sub %d',pp))
    saveas(h, sprintf('%s/sw_to_behavior/latency_pp_%d.svg',figures_save_path,pp))
end
%% plot SW rate
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).rate);
        triad_lengths_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).triad_lengths);
        rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        clim([-5 -3])
        set(gca, 'FontSize',fontsize)
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
    end
    colorbar;
    sgtitle(sprintf('SW JID and behavioral rate - Sub %d (No behavior removed)',pp))
    saveas(h, sprintf('%s/rates/rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW post rate
mins=1;
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).post_rate);
        rate_jid = cellfun(@(x) sum(x)/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        % clim([quantile(log10([rate_jid{:}]),[0.50, 0.90])])
        colorbar;
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
        set(gca, 'FontSize',fontsize)
    end
    colorbar
    sgtitle(sprintf('Rate %d min after SW dynamics - Sub %d (No Behavior removed)',mins,pp))
    saveas(h, sprintf('%s/rates/post_rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW pre rate
mins=1;
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).pre_rate);
        rate_jid = cellfun(@(x) sum(x)/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        clim([quantile(log10([rate_jid{:}]),[0.50, 0.90])])
        colorbar
        % clim([quantile(log10([pooled{:}]),[0.50, 0.90])])
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
        set(gca, 'FontSize',fontsize)
    end
    sgtitle(sprintf('Rate %d min before SW dynamics - Sub %d',mins,pp))
    saveas(h, sprintf('%s/rates/pre_rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW pre rate, rate and post rate
mins=1;
lim_data = [-4 -3];
fontsize = 10;
for pp=1:size(res,2)
    for chan =1:62
        h = figure;
        t = tiledlayout(3,3, 'TileSpacing', 'compact');
        % pre rate
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).pre_rate);
        % calculate the pre rate by taking the number of taps / N min window
        pre_rate_jid = cellfun(@(x) sum(x)/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        % find bins without any SWs and remove them
        empty_bins = cellfun(@(x) isempty(x),taps_on_sw{chan}, 'UniformOutput',0);
        pre_rate_jid(logical(cell2mat(empty_bins))) = {NaN};
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([pre_rate_jid{:}],50,50)+ 0.00000000001)); 
        title(sprintf('Pre Rate %d min',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        colorbar;
        set(gca, 'FontSize',fontsize) 
        % clim([-5 -3])

        % pre rate clims adjusted
        nexttile;
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([pre_rate_jid{:}],50,50)+ 0.00000000001)); 
        clim(lim_data)
        title(sprintf('Pre Rate %d min',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        colorbar;
        set(gca, 'FontSize',fontsize) 

        nexttile; 
        % remove the bins with no behavior
        pre_rate_jid(reshape([pre_rate_jid{:}] == 0, 50,50)) = {NaN};
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([pre_rate_jid{:}],50,50)+ 0.00000000001));
        colorbar;
        set(gca, 'FontSize',fontsize)
        title(sprintf('Pre Rate %d min - No behavior removed',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        % rate
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).rate);
        triad_lengths_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).triad_lengths);
        rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        colorbar;
        set(gca, 'FontSize',fontsize) 
        title('Rate')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        
        % rate adjusted lims
        nexttile;
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        clim(lim_data)
        colorbar;
        set(gca, 'FontSize',fontsize) 
        title('Rate')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        % rate no behavior
        nexttile; 
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001));
        colorbar;
        set(gca, 'FontSize',fontsize) 
        title('Rate - no behavior removed')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        % post rate
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).post_rate);
        post_rate_jid = cellfun(@(x) sum(x)/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        % find bins without any SWs and remove them
        empty_bins = cellfun(@(x) isempty(x),taps_on_sw{chan}, 'UniformOutput',0);
        post_rate_jid(logical(cell2mat(empty_bins))) = {NaN};
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([post_rate_jid{:}],50,50)+ 0.00000000001)); 
        colorbar;
        title(sprintf('Post Rate %d min',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        set(gca, 'FontSize',fontsize) 

        nexttile;
        plot_jid(log10(reshape([post_rate_jid{:}],50,50)+ 0.00000000001)); 
        colorbar;
        clim(lim_data)
        title(sprintf('Post Rate %d min',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        set(gca, 'FontSize',fontsize) 
        
        % post rate no behavior
        nexttile; 
        post_rate_jid(reshape([post_rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([post_rate_jid{:}],50,50)+ 0.00000000001)); 
        colorbar;
        set(gca, 'FontSize',fontsize)
        title(sprintf('Post Rate %d min - No behavior removed',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        sgtitle(t, sprintf('Chan:%d Subject:%d',chan,pp))
        saveas(h, sprintf('%s/rates/rates_pp_%d_chan_%d.svg',figures_save_path,pp,chan))
    end
end