max_all = max(cell2mat(cellfun(@(x) length(x),{refilter.channels.negzx},'UniformOutput',false)));
selected_waves = cell(64,length(max_all)-2);
triad_lengths = cell(64,length(max_all)-2);
% selected_waves = cellfun(@(x) NaN, num2cell(ones(64,max_all-2)), 'UniformOutput', false);
for chan=1:size(refilter.channels,2)
    slow_waves = [refilter.channels(chan).negzx{:}];
    for slow_waves_triad_idx = 1:length(slow_waves)-2
        triad = slow_waves(slow_waves_triad_idx:slow_waves_triad_idx+2);
        tmp = taps(taps >= triad(1) & taps <= triad(end));
        selected_waves{chan,slow_waves_triad_idx} = length(tmp);
        triad_lengths{chan,slow_waves_triad_idx} = triad(end)-triad(1);
    end
end
% [jid_delays_before(:,count),amp_per_triad_before,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_before,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
% count=count+1;
%% calculate rate
for chan =1:64
    h = figure;
    taps_on_sw = assign_input_to_bin([refilter.channels(chan).negzx{:}],selected_waves);
    triad_lengths_on_sw = assign_input_to_bin([refilter.channels(chan).negzx{:}],triad_lengths);
    rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
    plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); colorbar;
    title(sprintf('Chan %d',chan))
    set(gca, 'FontSize',18)
    saveas(h,sprintf('%s/rate_taps_in_sw_triad_%d.svg',save_path,chan))
end
%% post SW rate
max_all = max(cell2mat(cellfun(@(x) length(x),{refilter.channels.negzx},'UniformOutput',false)));
selected_waves = cell(64,length(max_all)-2);
triad_lengths = cell(64,length(max_all)-2);
mins = 1;
% selected_waves = cellfun(@(x) NaN, num2cell(ones(64,max_all-2)), 'UniformOutput', false);
for chan=1:size(refilter.channels,2)
    slow_waves = [refilter.channels(chan).negzx{:}];
    for slow_waves_triad_idx = 1:length(slow_waves)-2
        triad = slow_waves(slow_waves_triad_idx:slow_waves_triad_idx+2);
        % x min post SW event
        tmp = taps(taps >= triad(end) & taps <= triad(end)+(mins*60*1000));
        % x min pre SW event
        % tmp = taps(taps >= triad(1)-(mins*60*1000) & taps <= triad(1));
        selected_waves{chan,slow_waves_triad_idx} = length(tmp);
        triad_lengths{chan,slow_waves_triad_idx} = triad(end)-triad(1);
    end
end
%% plot post SW rate
for chan =1:64
    h = figure;
    taps_on_sw = assign_input_to_bin([refilter.channels(chan).negzx{:}],selected_waves);
    triad_lengths_on_sw = assign_input_to_bin([refilter.channels(chan).negzx{:}],triad_lengths);
    rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
    plot_jid(log10(reshape([rate_jid{:}],50,50)+ 0.00000000001)); colorbar;
    clim([quantile(log10([rate_jid{:}]),[0.50, 0.90])])
    title(sprintf('Chan %d',chan))
    set(gca, 'FontSize',18)
    saveas(h,sprintf('%s/rate_taps_post_sw_triad_%d.svg',save_path,chan))
end
%% plot latencies
max_all = max(cell2mat(cellfun(@(x) length(x),{refilter.channels.negzx},'UniformOutput',false)));
% next_tap = cell(64,length(max_all)-2);
next_tap = cellfun(@(x) NaN, num2cell(ones(64,max_all-2)), 'UniformOutput', false);
for chan=1:length(refilter.channels)
    slow_waves = [refilter.channels(chan).negzx{:}];
    for slow_waves_triad_idx = 1:length(slow_waves)-2
        triad = slow_waves(slow_waves_triad_idx:slow_waves_triad_idx+2);
        tmp = taps(taps > triad(end));
        if ~isempty(tmp)
            next_tap{chan,slow_waves_triad_idx} = tmp(1)-triad(end);
        end
    end
end
%% plot latencies
for chan =1:64
    h = figure;
    sw_to_behavior_latency = assign_input_to_bin([refilter.channels(chan).negzx{:}],next_tap);
    pooled = cellfun(@(x) median(x),sw_to_behavior_latency{chan},'UniformOutput', 0);
    plot_jid(log10(reshape([pooled{:}],50,50)+ 0.00000001)); colorbar;
    clim([quantile(log10([pooled{:}]),[0.10, 0.90])])
    title(sprintf('Chan %d',chan))
    set(gca, 'FontSize',18)
    saveas(h,sprintf('%s/latency_sw_to_next_tap_chan_%d.svg',save_path,chan))
end
%%
rate_jid = cellfun(@(x,y) sum(x)./sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
%% plot behavioral JID and corresponding SW triad(assigned to a bin)
for bin = 1:1136
    % bin = randi(size(selected_waves,2));
    tmp = selected_waves{chan,bin};
    if ~isempty(tmp) && length(tmp) > 3
        jid_behavior = taps2JID(tmp);

        h= figure;
        tiledlayout(1,2)
        nexttile;
        plot_jid(jid_behavior);
        axis square;
        title(sprintf('%d triad - size : %d',bin, length(tmp)))

        nexttile;
        input1 = num2cell(nan(1,length([refilter.channels(chan).negzx{:}])));
        input1{1,bin} = 1;
        JID = assign_input_to_bin([refilter.channels(chan).negzx{:}],input1);
        JID = cell2mat(cellfun(@(x) sum(~isempty(x) & ~isnan(x)) ,JID{chan} ,'UniformOutput' ,false));
        plot_jid(JID);

        set(gca, 'FontSize',18)
        colormap('parula')
        saveas(h, sprintf('%s/chan_%d_triad_%d.svg',save_path,chan,bin))
    end
end
%% plot movie sequence of behavioral JID and corresponding SW triad(assigned to a bin)
for pp=1
    refilter = res(pp).refilter;
    taps = res(pp).taps;
    [dt_dt,~] = calculate_ITI_K_ITI_K1([refilter.channels(chan).negzx{:}]);
    [dt_dt,gridx] = assign_tap2bin(dt_dt);

    max_all = max(cell2mat(cellfun(@(x) length(x),{refilter.channels.negzx},'UniformOutput',false)));
    selected_waves = cell(64,length(max_all)-2);
    triad_lengths = cell(64,length(max_all)-2);

    % selected_waves = cellfun(@(x) NaN, num2cell(ones(64,max_all-2)), 'UniformOutput', false);
    for chan=1:size(refilter.channels,2)
        slow_waves = [refilter.channels(chan).negzx{:}];
        for slow_waves_triad_idx = 1:length(slow_waves)-2
            triad = slow_waves(slow_waves_triad_idx:slow_waves_triad_idx+2);
            tmp = taps(taps >= triad(1) & taps <= triad(end));
            selected_waves{chan,slow_waves_triad_idx} = tmp;
            triad_lengths{chan,slow_waves_triad_idx} = triad(end)-triad(1);
        end
    end
    %
    figure;
    v = VideoWriter(sprintf('%s/sw_to_behavior/movie_chan_%d_pp_%d.avi',figures_save_path,chan,pp));
    v.FrameRate = 5;
    open(v)
    [x,idx] = sortrows(dt_dt(:,3:4), [1 2]);
    for bin = 1:length(idx)
        tmp = selected_waves{chan,idx(bin)};
        if ~isempty(tmp) && length(tmp) > 3
            tiledlayout(1,2);
            ax1 = nexttile;
            jid_behavior = taps2JID(tmp);
            plot_jid(jid_behavior);
            freezeColors;
            colorbar(ax1, 'Location', 'eastoutside');
            axis square;
            title(sprintf('%d triad - size : %d',bin, length(tmp)));

            hold off;
            ax2 = nexttile;
            input1 = num2cell(nan(1,length([refilter.channels(chan).negzx{:}])));
            input1{1,idx(bin)} = 1;
            JID = assign_input_to_bin([refilter.channels(chan).negzx{:}],input1);
            JID = cell2mat(cellfun(@(x) sum(~isempty(x) & ~isnan(x)) ,JID{1} ,'UniformOutput' ,false));
            plot_jid(JID);

            colorbar;

            shg;
            %supertitle(strcat(num2str(i-5000),{' '},'ms'), 'FontSize', 40);
            set(gcf,'color','w');
            M =getframe(gcf);
            writeVideo(v,M);
            %    namef = strcat(num2str(i), '_t_',num2str(i-4000), '.png') ;
            %saveas(gcf, namef);
            clf;
        end
    end
    close(v);
end
%% plot adjacent SW's and behavior
max_all = max(cell2mat(cellfun(@(x) length(x),{refilter.channels.negzx},'UniformOutput',false)));
selected_waves = cell(64,length(max_all)-2);
triad_lengths = cell(64,length(max_all)-2);
% selected_waves = cellfun(@(x) NaN, num2cell(ones(64,max_all-2)), 'UniformOutput', false);
for chan=1:size(refilter.channels,2)
    slow_waves = [refilter.channels(chan).negzx{:}];
    for slow_waves_triad_idx = 1:length(slow_waves)-2
        triad = slow_waves(slow_waves_triad_idx:slow_waves_triad_idx+2);
        tmp = taps(taps >= triad(1) & taps <= triad(end));
        selected_waves{chan,slow_waves_triad_idx} = {tmp};
        triad_lengths{chan,slow_waves_triad_idx} = triad(end)-triad(1);
    end
end
%%
n_neighbors = 2;
ADJ = find_adj_matrix(50, n_neighbors);
taps_on_sw = assign_input_to_bin([refilter.channels(chan).negzx{:}],selected_waves);
for bin=1:2500
    tmp = taps_on_sw{chan};
    tmp = reshape(tmp, 2500,1);
    bins_behavior = ~logical(cellfun(@(x) isempty(x), tmp));
    bins_neighbors = logical(ADJ(bin,:))';
    bins_of_interest = bins_neighbors & bins_behavior;
    selected = find(bins_of_interest);
    selected_bins = cellfun(@(x) cellfun(@(y) length(y) > 3,x) ,tmp(selected) ,'UniformOutput' ,false);
    all_bins_plotted = [];
    if sum([selected_bins{:}])
        h = figure;
        tiledlayout(1,sum([selected_bins{:}])+1)
        for i=1:length(selected)
            s = find(selected_bins{i});
            for j=1:sum(selected_bins{i})
                nexttile;
                jid_behavior = taps2JID(tmp{selected(i)}{s(j)});
                plot_jid(jid_behavior);
                all_bins_plotted = [all_bins_plotted, selected(i)];
                title(sprintf('bin %d',selected(i)))
            end
        end
        nexttile;
        jid = zeros(1,2500);
        jid(all_bins_plotted) = 1;
        plot_jid(reshape(jid,50,50))
        saveas(h, sprintf('%s/adj_%d_bin_%d_chan_%d.svg',save_path,n_neighbors,bin,chan))
        close(h)
    end
end