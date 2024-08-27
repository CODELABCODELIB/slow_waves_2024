%% plot SW jids
for pp=1:size(res,2)
    h = figure;
    tiledlayout(8,8, 'TileSpacing','compact')
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
for pp=1:41
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        sw_to_behavior_latency = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).latency);
        pooled = cellfun(@(x) median(x),sw_to_behavior_latency{chan},'UniformOutput', 0);
        plot_jid(log10(reshape([pooled{:}],50,50)+ 0.00000001));
        clim([quantile(log10([pooled{:}]),[0.10, 0.90])])
        set(gca, 'FontSize',18)
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
    end
    sgtitle(sprintf('Time to next tap (ms)- Sub %d',pp))
    saveas(h, sprintf('%s/sw_to_behavior/latency_pp_%d.svg',figures_save_path,pp))
end
%% plot SW rate
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','compact')
    for chan =1:25
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).rate);
        triad_lengths_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).triad_lengths);
        rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        clim([-5 -3])
        % set(gca, 'FontSize',18)
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
    end
    sgtitle(sprintf('SW JID and behavioral rate - Sub %d (No behavior removed)',pp))
    saveas(h, sprintf('%s/rates/rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW post rate
mins=1;
for pp=1:41
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).post_rate);
        rate_jid = cellfun(@(x) sum(x)/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        clim([quantile(log10([rate_jid{:}]),[0.50, 0.90])])
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
        set(gca, 'FontSize',18)
    end
    sgtitle(sprintf('Rate %d min after SW dynamics - Sub %d',mins,pp))
    saveas(h, sprintf('%s/rates/post_rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW pre rate
mins=1;
for pp=1:41
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).pre_rate);
        rate_jid = cellfun(@(x) sum(x)/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); 
        % clim([quantile(log10([pooled{:}]),[0.50, 0.90])])
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d',chan))
        set(gca, 'FontSize',18)
    end
    sgtitle(sprintf('Rate %d min before SW dynamics - Sub %d',mins,pp))
    saveas(h, sprintf('%s/rates/pre_rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW pre rate, rate and post rate
mins=1;
lim_data = [];
for pp=2:2
    for chan =1:1
        h = figure;
        t = tiledlayout(3,2, 'TileSpacing', 'compact');
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
        title(sprintf('Post Rate %d min',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        colorbar;
        set(gca, 'FontSize',18) 
        % clim([-5 -3])

        nexttile; 
        % remove the bins with no behavior
        pre_rate_jid(reshape([pre_rate_jid{:}] == 0, 50,50)) = {NaN};
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([pre_rate_jid{:}],50,50)+ 0.00000000001));
        colorbar;
        set(gca, 'FontSize',18)
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
        if lim_data
            clim([lim_data])
        end
        colorbar;
        set(gca, 'FontSize',18) 
        title('Rate')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        % rate no behavior
        nexttile; 
        rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001));
        colorbar;
        set(gca, 'FontSize',18) 
        if lim_data
            clim([lim_data])
        end
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
        if lim_data
            clim([lim_data])
        end
        set(gca, 'FontSize',18) 
        
        % post rate no behavior
        nexttile; 
        post_rate_jid(reshape([post_rate_jid{:}] == 0, 50,50)) = {NaN};
        plot_jid(log10(reshape([post_rate_jid{:}],50,50)+ 0.00000000001)); 
        colorbar;
        set(gca, 'FontSize',18)
        title(sprintf('Post Rate %d min - No behavior removed',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        sgtitle(t, sprintf('Chan:%d Subject:%d',chan,pp))
        saveas(h, sprintf('%s/rates/rates_pp_%d_chan_%d.svg',figures_save_path,pp,chan))
    end
    % 
end