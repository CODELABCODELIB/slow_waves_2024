N=5;
n_boots =1000;
% bootstrap_matrix_behavior = zeros(64,max([res(pp).behavior_sws{:}], [], 'all'));
for pp=1:length(res)
    for chan =1:64 
        bootstraps = cell(1,n_boots);
        SWs = [res(pp).behavior_sws{chan,:}];
        n_sws = floor(size(SWs,2)/5);
        for boots=1:n_boots     
            bootstrap_matrix_SWs = nan(1,n_sws*5);
            count = 1;
            for i=1:floor(size(SWs,2)/5)
                sel_SW_int = randi([1,size(SWs,2)-N]);
                selected_SWs = SWs(sel_SW_int:sel_SW_int+N);
                intervals = [0,diff(selected_SWs)];
                random_time_point = randi([min(SWs),max(SWs)]);
                selected_time_points = zeros(size(intervals));
                selected_time_points(1) = random_time_point;
                for in = 2:length(intervals)
                    selected_time_points(in) = selected_time_points(in-1)+intervals(in);
                end
                if selected_time_points(end) > max([res(pp).behavior_sws{:}], [], 'all')
                    continue;
                end
                bootstrap_matrix_SWs(count:count+5) = selected_time_points;
                count = count + 5;
            end
            bootstraps{1,boots} = bootstrap_matrix_SWs;
        end
        save(sprintf('%s/sw_boots/pp_%d_chan_%d.mat',save_path_upper,pp,chan), 'bootstraps', '-v7.3')
    end
end
%%
tmp = cellfun(@(y) y(1:min(cellfun(@(x) length(x),bootstraps))),bootstraps,'UniformOutput',false);
boots = cat(1,tmp{:});
%%
boot_rasters = cell(64,length(res));
for pp=1:1
    taps = zeros(1, max([res(pp).behavior_sws{:}], [], 'all'));
    taps(round(res(pp).taps)) = 1;
    for chan=1:64
        sw_indexes = bootstraps{chan,pp};
        behavior_raster = zeros(length(sw_indexes),time_range*2);
        for i=1:length(sw_indexes)
            if sw_indexes(i)-time_range > 0 && sw_indexes(i)+time_range < length(taps)
                behavior_raster(i,:) = taps(sw_indexes(i)-time_range:sw_indexes(i)+time_range-1);
            end
        end
        boot_rasters{chan,pp} = sum(behavior_raster);
    end
end
%%
for pp=1:1
    tmp = cat(1,boot_rasters{:,pp});
    x = sum(tmp,1);
    ksarray_boot = [];
    for i = 1:length(x)
        ksarray_boot = [ksarray_boot, repmat(pnts(i), 1, x(i))];
    end

    tmp = cat(1,rasters{:,pp});
    x = sum(tmp,1);
    ksarray = [];
    for i = 1:length(x)
        ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
    end

    figure;  
    ksdensity(ksarray_boot, pnts, 'Bandwidth',0.1)
    hold on;
    ksdensity(ksarray, pnts, 'Bandwidth',0.1)
    xline(0, 'Linewidth', 2);
    set(gca, 'FontSize', 18); 
    box off;
    sgtitle(sprintf('Sub %d', pp))
    legend({'Boot', 'Original'})
end
