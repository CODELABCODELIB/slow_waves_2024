max_all = max(cell2mat(cellfun(@(x) length(x),{refilter.channels.negzx},'UniformOutput',false)));
selected_waves = cell(64,length(max_all)-2);
selected_waves = cell(64,length(max_all)-2);
% selected_waves = cellfun(@(x) NaN, num2cell(ones(64,max_all-2)), 'UniformOutput', false);
for chan=1:length(refilter.channels)
    slow_waves = [refilter.channels(chan).negzx{:}];
    for slow_waves_triad_idx = 1:length(slow_waves)-2
        triad = slow_waves(slow_waves_triad_idx:slow_waves_triad_idx+2);
        tmp = taps(taps >= triad(1) & taps <= triad(end));
        selected_waves{chan,slow_waves_triad_idx} = tmp;
    end
end
% [jid_delays_before(:,count),amp_per_triad_before,not_occupied_bins] = jid_per_param(refilter.channels,selected_waves_before,dt_dt_r, f, 'sel_field',"maxpospkamp", 'pool_duplicates', 0);
% count=count+1;
%%
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
%%
figure;
v = VideoWriter('sw_to_behavior.avi');
v.FrameRate = 30;
open(v)
for bin = 1:1136
    tmp = selected_waves{chan,bin};
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
         input1{1,bin} = 1;
         JID = assign_input_to_bin([refilter.channels(chan).negzx{:}],input1);
         JID = cell2mat(cellfun(@(x) sum(~isempty(x) & ~isnan(x)) ,JID{chan} ,'UniformOutput' ,false));
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
%%
ADJ = find_adj_matrix(50, 10);
taps_on_sw = assign_input_to_bin([refilter.channels(chan).negzx{:}],selected_waves);
for bin=1:2500
    tmp = taps_on_sw{chan};
    tmp(~logical(reshape(ADJ(bin,:),50,50))) = num2cell(NaN);
    non_empty_bins = cell2mat(cellfun(@(x) all(isnan(x)),tmp, 'UniformOutput', 0));
    if ~all(non_empty_bins, 'all')
        h = figure; 
        selected = find(~cell2mat(cellfun(@(x) all(isnan(x)),tmp, 'UniformOutput', 0)));
        tiledlayout(1,length(selected))
        for i = 1:length(selected)
            if length(rmmissing(tmp{selected(i)})) > 3
               
                nexttile;
                jid_behavior = taps2JID(rmmissing(tmp{selected(i)}));
            end
        end
        if ~sum(cellfun(@(x) length(rmmissing(x)) > 3 ,tmp(selected)))
            close(h)
        end
    end
    % x = reshape(tmp{chan},2500,1); 
    % x(logical(ADJ(bin,:)));
end