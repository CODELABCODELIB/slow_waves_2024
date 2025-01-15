figures_save_path = sprintf('%s/dec_rerun',figures_save_path);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% pop level plots %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% behavior sw jid
behavior_sw_jid = cell(length(res),64);
for pp=1:length(res)
    for chan =1:64
        behavior_sw_jid{pp,chan} = taps2JID([res(pp).behavior_sws{chan,:}]);
    end
end
save_path = sprintf('%s/pop/behavior_sw_jid.svg',figures_save_path);
population_sw_to_behavior_plots(behavior_sw_jid, EEG.Orignalchanlocs, 'color_lims', [0, 0.6], 'show_title', 0,'save_path',save_path);
save_path = sprintf('%s/pop/behavior_sw_jid_title.svg',figures_save_path);
population_sw_to_behavior_plots(behavior_sw_jid, EEG.Orignalchanlocs, 'color_lims', [0, 0.6], 'show_title', 1,'save_path',save_path);
%% movie sw jid
movie_sw_jid = cell(length(res),64);
for pp=1:length(res)
    for chan =1:64
        movie_sw_jid{pp,chan} = taps2JID([res(pp).movie_sws{chan,:}]);
    end
end
save_path = sprintf('%s/pop/movie_sw_jid.svg',figures_save_path);
population_sw_to_behavior_plots(movie_sw_jid, EEG.Orignalchanlocs, 'color_lims', [0, 0.5], 'show_title', 0,'save_path',save_path);
save_path = sprintf('%s/pop/movie_sw_jid_title.svg',figures_save_path);
population_sw_to_behavior_plots(movie_sw_jid, EEG.Orignalchanlocs, 'color_lims', [0, 0.5], 'show_title', 1,'save_path',save_path);
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Individual level plots %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot SW jids
for pp=1:size(res,2)
    h = figure;
    tiledlayout(8,8, 'TileSpacing','none')
    % estimate the SW jid per channel
    for chan=1:62
        jid = taps2JID([res(pp).behavior_sws{chan,:}]);
        nexttile;
        plot_jid(jid);
        clim([0 0.8]);
        % set(gca, 'visible','off')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Chan %d - N %d',chan, length([res(pp).behavior_sws{chan,:}])))
    end
    sgtitle(sprintf('SW JID - Sub %d',pp))
    saveas(h, sprintf('%s/sw_to_behavior/jid_sw_pp_behavior_%d.svg',figures_save_path,pp))
end
%% plot SW jids movie vs phone
n_chans = 15;
for pp=1:size(res,2)
    h = figure;
    tiledlayout(2,n_chans, 'TileSpacing','none')
    taps = res(pp).taps;
    for chan=1:n_chans
        % estimate the SW jid per channel
        jid = taps2JID([res(pp).behavior_sws{chan,:}]);
        nexttile;
        plot_jid(jid);
        title(sprintf('C %d - N %d',chan, length([res(pp).behavior_sws{chan,:}])))
        clim([0 0.8]);
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
    end
    for chan=1:n_chans
        slow_waves_start = [res(pp).refilter.channels(chan).maxnegpk{:}];
        movie_sws = slow_waves_start(slow_waves_start<=taps(1));
        jid = taps2JID(movie_sws);
        nexttile;
        plot_jid(jid);
        title(sprintf('C %d - N %d',chan, length(movie_sws)))
        clim([0 0.8]);
        % set(gca, 'visible','off')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
    end
    sgtitle(sprintf('SW JID - Sub %d',pp))
    saveas(h, sprintf('%s/sw_to_behavior/jid_sw_movie_vs_behavior_pp_%d.svg',figures_save_path,pp))
end
%% latency JID2D
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    taps = res(pp).taps;
    for chan =1:25
        nexttile;
        sw_to_behavior_latency = assign_input_to_bin([res(pp).behavior_sws{chan,:}], res(pp).latency);
        pooled = cellfun(@(x) median(x,'omitnan'),sw_to_behavior_latency{chan},'UniformOutput', 0);
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
%% latency 1D
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        nexttile;
        tmp = [res(pp).latency{chan,:}];
        tmp = tmp(tmp > 0);
        histogram(tmp);
        title(sprintf('Chan %d',chan))
    end
    sgtitle(sprintf('Time to next tap (Log10[ms])- Sub %d',pp))
    saveas(h, sprintf('%s/sw_to_behavior/latency_hist_pp_%d.svg',figures_save_path,pp))
end
%% plot SW rate individual
fontsize = 10;
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        if length([res(pp).behavior_sws{chan,:}])>3
            nexttile;
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).rate);
            triad_lengths_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).triad_lengths);
            rate_jid = cellfun(@(x,y) sum(x, 'omitnan')/sum(y, 'omitnan'),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
            % rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
            plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001));
            clim([-5 -3])
            % clim([quantile(log10([rate_jid{:}]),[0.10, 0.90])])
            set(gca, 'FontSize',fontsize)
            xlabel('K (log10[ms])')
            ylabel('K+1 (log10[ms])')
            title(sprintf('Chan %d',chan))
        end
    end
    colorbar;
    sgtitle(sprintf('SW JID and behavioral rate - Sub %d (No behavior removed)',pp))
    saveas(h, sprintf('%s/rates/rate_pp_%d.svg',figures_save_path,pp))

end
% close all;
%% plot SW rate pooled
rate_jid = cell(64,length(res));
fontsize = 10;
for pp=1:length(res)
    for chan =1:64
        if length([res(pp).behavior_sws{chan,:}])>3
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).rate);
            triad_lengths_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).triad_lengths);
            rate_jid{chan,pp} = cellfun(@(x,y) sum(x, 'omitnan')/sum(y, 'omitnan'),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
        end
    end
end
%% plot the pooled sw rate JID
rj = cat(3,cellfun(@(jid) log10(reshape([jid{:}],2500,1)+0.00000000001),rate_jid,'UniformOutput',false));
figure; 
tiledlayout(8,8, 'TileSpacing','none')
[sorted_idx] = sort_electrodes(EEG.Orignalchanlocs); 
for chan=sorted_idx
    nexttile;
    tmp = cat(2,rj{chan,:});
    plot_jid(reshape(trimmean(tmp,20,2),50,50));
    clim([-11,-3])
    % set(gca, 'visible', 'off')
end
%% plot SW post rate
mins=1;
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        if length([res(pp).behavior_sws{chan,:}])>3
            nexttile;
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).post_rate);
            post_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
            % rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
            empty_bins = cellfun(@(x) isempty(x),taps_on_sw{chan}, 'UniformOutput',0);
            post_rate_jid(logical(cell2mat(empty_bins))) = {NaN};
            plot_jid(log10(reshape([post_rate_jid{:}],50,50)+ 0.00000000001));
            % clim([quantile(log10([post_rate_jid{:}]),[0.10, 0.90])])
            clim([-4,-3])
            colorbar;
            xlabel('K (log10[ms])')
            ylabel('K+1 (log10[ms])')
            title(sprintf('Chan %d',chan))
            set(gca, 'FontSize',fontsize)
        end
    end
    colorbar
    sgtitle(sprintf('Rate %d min after SW dynamics - Sub %d',mins,pp))
    saveas(h, sprintf('%s/rates/post_rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW pre rate
mins=1;
for pp=1:size(res,2)
    h = figure;
    tiledlayout(5,5, 'TileSpacing','none')
    for chan =1:25
        if length([res(pp).behavior_sws{chan,:}])>3
            nexttile;
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).pre_rate);
            pre_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
            pre_rate_jid(reshape([pre_rate_jid{:}] == 0, 50,50)) = {NaN};
            plot_jid(log10(reshape([pre_rate_jid{:}],50,50)+ 0.00000000001));
            % clim([quantile(log10([pre_rate_jid{:}]),[0.10, 0.90])])
            clim([-4, -3])
            colorbar
            xlabel('K (log10[ms])')
            ylabel('K+1 (log10[ms])')
            title(sprintf('Chan %d',chan))
            set(gca, 'FontSize',fontsize)
        end
    end
    sgtitle(sprintf('Rate %d min before SW dynamics - Sub %d',mins,pp))
    saveas(h, sprintf('%s/rates/pre_rate_pp_%d.svg',figures_save_path,pp))
end
%% plot SW pre rate, rate and post rate
mins=1;
lim_data = [-4 -3];
fontsize = 10;
% for pp=1:size(res,2)
for pp=1:41
    for chan =1:10
        h = figure;
        t = tiledlayout(3,3, 'TileSpacing', 'compact');
        % pre rate
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).pre_rate);
        % calculate the pre rate by taking the number of taps / N min window
        pre_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
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
        % clim([-4 -3])

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
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).rate);
        triad_lengths_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).triad_lengths);
        rate_jid = cellfun(@(x,y) sum(x, 'omitnan')/sum(y, 'omitnan'),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
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
        clim([-4,-3])
        colorbar;
        set(gca, 'FontSize',fontsize)
        % title('Rate')
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
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).post_rate);
        post_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
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
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).pre_rate);
        % calculate the pre rate by taking the number of taps / N min window
        pre_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        % find bins without any SWs and remove them
        empty_bins = cellfun(@(x) isempty(x),taps_on_sw{chan}, 'UniformOutput',0);
        pre_rate_jid(logical(cell2mat(empty_bins))) = {NaN};
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
close all;
%% plot SW features
mins=1;
lim_data = [-4 -3];
fontsize = 10;
% for pp=1:size(res,2)
n_chan = 6;
for pp=1:41
    h = figure;
    t = tiledlayout(n_chan,6, 'TileSpacing', 'none');
    for chan =1:n_chan
        % JID SW
        nexttile;
        jid = taps2JID([res(pp).behavior_sws{chan,:}]);
        plot_jid(jid);
        % clim([0,0.6])
        % set(gca, 'visible','off')
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('SW-JID Chan %d',chan))

        % JID Amplitude
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).amplitude);
        sw_jid_amplitude = cellfun(@(x) median(x, 'omitnan'),taps_on_sw{chan}, 'UniformOutput',0);
        plot_jid(reshape([sw_jid_amplitude{:}],50,50))
        colorbar;
        clim(quantile([sw_jid_amplitude{:}], [0.25, 0.75]))
        title(sprintf('SW-Amplitude Chan %d',chan))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        % latency
        nexttile;
        sw_to_behavior_latency = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).latency);
        pooled = cellfun(@(x) median(x,'omitnan'),sw_to_behavior_latency{chan},'UniformOutput', 0);
        plot_jid(log10(reshape([pooled{:}],50,50)+ 0.00000001));
        clim([quantile(log10([pooled{:}]),[0.05, 0.95])])
        colorbar;
        set(gca, 'FontSize',10)
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        title(sprintf('Latency Chan %d',chan))

        % rate
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).rate);
        triad_lengths_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).triad_lengths);
        rate_jid = cellfun(@(x,y) sum(x, 'omitnan')/sum(y, 'omitnan'),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001));
        colorbar;
        clim(lim_data)
        set(gca, 'FontSize',fontsize)
        title(sprintf('Rate Chan %d',chan))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')

        % pre rate
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).pre_rate);
        % calculate the pre rate by taking the number of taps / N min window
        pre_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        % find bins without any SWs and remove them
        empty_bins = cellfun(@(x) isempty(x),taps_on_sw{chan}, 'UniformOutput',0);
        pre_rate_jid(logical(cell2mat(empty_bins))) = {NaN};
        plot_jid(log10(reshape([pre_rate_jid{:}],50,50)+ 0.00000000001));
        title(sprintf('Pre Rate %d min',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
         clim(lim_data)
        colorbar;
        set(gca, 'FontSize',fontsize)
        title(sprintf('Pre-Rate Chan %d',chan))

        % post rate
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).post_rate);
        post_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
        % find bins without any SWs and remove them
        empty_bins = cellfun(@(x) isempty(x),taps_on_sw{chan}, 'UniformOutput',0);
        post_rate_jid(logical(cell2mat(empty_bins))) = {NaN};
        % log transform the data and pad the 0's so they are not -inf and plot the jid
        plot_jid(log10(reshape([post_rate_jid{:}],50,50)+ 0.00000000001));
        colorbar;
         clim(lim_data)
        title(sprintf('Post Rate %d min',mins))
        xlabel('K (log10[ms])')
        ylabel('K+1 (log10[ms])')
        set(gca, 'FontSize',fontsize)

        sgtitle(t, sprintf('Subject:%d',pp))
        saveas(h, sprintf('%s/sw_to_behavior/summary_%d.svg',figures_save_path,pp))
    end
end
%% Plot JID-amplitdes
for pp=1:size(res,2)
    h = figure;
    tiledlayout(8,8, 'TileSpacing','none')
    % estimate the SW jid per channel
    for chan=1:62
        nexttile;
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).amplitude);
        sw_jid_amplitude = cellfun(@(x) median(x, 'omitnan'),taps_on_sw{chan}, 'UniformOutput',0);
        plot_jid(reshape([sw_jid_amplitude{:}],50,50))
        colorbar;
        range = quantile([sw_jid_amplitude{:}], [0.05, 0.95]);
        title(sprintf('E%d R %.0f - %.0f',chan,floor(range(1)),ceil(range(2))))
        clim(quantile([sw_jid_amplitude{:}], [0.25, 0.75]))
    end
    sgtitle(sprintf('SW-JID amplitudes (no log transformation) - Sub:%d',pp))
    saveas(h, sprintf('%s/sw_to_behavior/sw_jid_amplitudes_pp_%d.svg',figures_save_path,pp))
end
%% plot JID-SW std/length
% for pp=1:size(res,2)
%     max_all = max(cell2mat(cellfun(@(x) length(x),{res(pp).refilter.channels.maxnegpk},'UniformOutput',false)));
%     selected_waves = cell(64,length(max_all)-2);
%     for chan=1:size(res(pp).refilter.channels,2)
%         slow_waves = [res(pp).refilter.channels(chan).maxnegpk{:}];
%         neg_amplitudes = [res(pp).refilter.channels(chan).maxnegpkamp{:}];
%         pos_amplitudes = [res(pp).refilter.channels(chan).maxpospkamp{:}];
%         for triad_idx = 1:length(slow_waves)-2
%             triad_neg = neg_amplitudes(triad_idx:triad_idx+2);
%             triad_pos = pos_amplitudes(triad_idx:triad_idx+2);
%             triad = abs(triad_pos-triad_neg);
%             selected_waves{chan,triad_idx} = triad;
%         end
%     end
%     h = figure;
%     tiledlayout(8,8, 'TileSpacing','none')
%     % estimate the SW jid per channel
%     for chan=1:64
%         nexttile;
%         taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).maxnegpk{:}],selected_waves);
%         sw_jid_amplitude = cellfun(@(x) length(x),taps_on_sw{chan}, 'UniformOutput',0);
%         plot_jid(reshape([sw_jid_amplitude{:}],50,50))
%         colorbar;
%         title(sprintf('chan %d',chan))
%         axis square;
%         clim(quantile([sw_jid_amplitude{:}], [0.25, 0.95]))
%     end
%     sgtitle(sprintf('SW-JID amplitudes length (no log transformation) - Sub:%d',pp))
%     saveas(h, sprintf('%s/sw_to_behavior/sw_jid_amplitudes_len_pp_%d.svg',figures_save_path,pp))
% end
% close all;
% %% plot JID-SW slopes
% parameter = 'mxupslp';
% for pp=1:size(res,2)
%     max_all = max(cell2mat(cellfun(@(x) length(x),{res(pp).refilter.channels.maxnegpk},'UniformOutput',false)));
%     selected_waves = cell(64,length(max_all)-2);
%     for chan=1:size(res(pp).refilter.channels,2)
%         slow_waves = [res(pp).refilter.channels(chan).maxnegpk{:}];
%         slope = [res(pp).refilter.channels(chan).(parameter){:}];
%         for triad_idx = 1:length(slow_waves)-2
%             triad = slope(triad_idx:triad_idx+2);
%             selected_waves{chan,triad_idx} = triad;
%         end
%     end
%     h = figure;
%     tiledlayout(8,8, 'TileSpacing','none')
%     % estimate the SW jid per channel
%     for chan=1:64
%         nexttile;
%         taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).maxnegpk{:}],selected_waves);
%         sw_jid_amplitude = cellfun(@(x) median(x, 'omitnan'),taps_on_sw{chan}, 'UniformOutput',0);
%         plot_jid(reshape([sw_jid_amplitude{:}],50,50))
%         colorbar;
%         title(sprintf('chan %d',chan))
%         clim(quantile([sw_jid_amplitude{:}], [0.25, 0.75]))
%         axis square;
%     end
%     sgtitle(sprintf('SW-JID slope (no log transformation) - Sub:%d',pp))
%     saveas(h, sprintf('%s/sw_to_behavior/sw_jid_%s_pp_%d.svg',figures_save_path,parameter,pp))
% end