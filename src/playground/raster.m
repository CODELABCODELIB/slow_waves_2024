time_range = 2000;
pnts = -time_range-1:time_range;
rasters = cell(64,length(res));
for pp=1:length(res)
    for chan=1:62
        tmp = [res(pp).behavior_sws{chan,:}];
        behavior_raster = zeros(length(tmp),time_range*2);
        for i=1:length(tmp)
            taps_in_window = res(pp).taps >= tmp(i)-time_range & res(pp).taps <= tmp(i)+time_range;
            tap_indexes = res(pp).taps(taps_in_window);
            behavior_raster(i,:) = ismember(tmp(i)-(time_range-1):tmp(i)+time_range,tap_indexes);
        end
        rasters{chan,pp} = behavior_raster;
    end
end
%% raster plot per pp and per channel
figure;
tiledlayout(2,1);
nexttile;
imagesc([-time_range-1:time_range],[1:size(rasters{chan,pp},1)],rasters{chan,pp});
set(gca, 'FontSize', 18); box off;
xline(0, 'Linewidth', 2);
nexttile;
x= sum(rasters{chan,pp});
ksarray = [];
for i = 1:length(x)
    ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
end
% plot([-999:1000],sum(rasters{chan,pp})./size(rasters{chan,pp},1) * 100);
ksdensity(ksarray,pnts)
set(gca, 'FontSize', 18); box off;
xlabel('Time')
ylabel('%')
xline(0)
sgtitle(sprintf('Chan %d', chan))
%% all pp overlayed per channel
for chan =1:64
    figure;
    hold on;
    for pp=1:length(res)
        x= sum(rasters{chan,pp});
        ksarray = [];
        for i = 1:length(x)
            ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
        end
        ksdensity(ksarray,pnts,'BoundaryCorrection','reflection')
    end
    set(gca, 'FontSize', 18); box off;
    xline(0, 'Linewidth', 2);
    sgtitle(sprintf('Chan %d',chan))
   xlim([-(time_range-1000),time_range-1000])
end
%% per pp across all channels
for pp=1:length(res)
    figure;
    tmp = cat(1,rasters{:,pp});
    plot(pnts,sum(tmp./size(tmp,1) * 100));
    xline(0, 'Linewidth', 2);
    set(gca, 'FontSize', 18); box off;
    sgtitle(sprintf('Sub %d', pp))
end
%% per pp across all channels ksdensity
for pp=1:length(res)
    tmp = cat(1,rasters{:,pp});
    x = sum(tmp,1);
    ksarray = [];
    for i = 1:length(x)
        ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
    end
    figure;  
    ksdensity(ksarray, pnts, 'Bandwidth',0.1)
    xline(0, 'Linewidth', 2);
    set(gca, 'FontSize', 18); 
    box off;
    sgtitle(sprintf('Sub %d', pp))
end
%% per channel across the population ksdensity
for chan=1:64
    figure;
    tmp = cat(1,rasters{chan,:});
    plot([-999:1000],sum(tmp./size(tmp,1) * 100));
    xline(0, 'Linewidth', 2);
    set(gca, 'FontSize', 18); box off;
    sgtitle(sprintf('Chan %d', chan))
end
%% per channel across the population ksdensity
pnts = -999:1000;
for chan=1:64
    tmp = cat(1,rasters{chan,:});
    x = sum(tmp,1);
    ksarray = [];
    for i = 1:length(x)
        ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
    end
    figure; 
    tiledlayout(2,1)
    nexttile;
    ksdensity(ksarray, pnts)
    xline(0, 'Linewidth', 2);
    set(gca, 'FontSize', 18); 
    box off;
    nexttile;
    histogram(ksarray);
    set(gca, 'FontSize', 18); 
    sgtitle(sprintf('Chan %d', chan))
end
%% Population level - pooled across channels
figure; 
hold on;
for chan=1:64
    tmp = cat(1,rasters{chan,:});
    x = sum(tmp,1);
    ksarray = [];
    for i = 1:length(x)
        ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
    end
    [f,x1] = ksdensity(ksarray, pnts);
    plot(x1,f, 'color', [0 0 0 0.3]);
end
title('Population level - pooled across channels')
xline(0, 'Linewidth', 2);
set(gca, 'FontSize', 18);
%% all pp overlayed per channel
figure;
tiledlayout(8,8)
for chan =1:64
    all_subjects = zeros(length(res),length(pnts));
    for pp=1:length(res)
        x= sum(rasters{chan,pp});
        ksarray = [];
        for i = 1:length(x)
            ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
        end
        [f,xi] = ksdensity(ksarray,pnts);
        all_subjects(pp,:) = f;
    end
    nexttile;
    plot(xi,median(all_subjects))
    set(gca, 'FontSize', 18); box off;
    xline(0, 'Linewidth', 2);
    title(sprintf('Chan %d',chan))
     set(gca,'visible', 'off')
   xlim([-(time_range-1000),time_range-1000])
end
%% Grouped by lobes
contr_sensorimotor = [46,47,48,30,31,32,17,16,18];
ipsi_sensorimotor = [8,9,10,20,21,22,35,36,37,38];
central = [1,2,3,4,5,6];
frontal = [49,34,35,33,19,20,21,50,60];
occipital = [13,14,12,27,26,25,28,42,43,41,56,55,54];
groups = {contr_sensorimotor,ipsi_sensorimotor,central,frontal,occipital};
colors = {[0 0 0 0.3],[1 0 0 0.3],[0 1 0 0.3],[0 0 1 0.3],[0 1 1 0.3]};
legends = {};
fig = figure; 
hold on;
for group_idx=1:length(groups)
    group=groups{group_idx};
    for chan=group
        tmp = cat(1,rasters{chan,:});
        x = sum(tmp,1);
        ksarray = [];
        for i = 1:length(x)
            ksarray = [ksarray, repmat(pnts(i), 1, x(i))];
        end
        [f,x1] = ksdensity(ksarray, pnts);
        h = plot(x1,f, 'color', colors{group_idx}, 'Linewidth',2);
    end
    legends{group_idx} = h;
end
title('Population level - pooled across channels')
xline(0, 'Linewidth', 2);
set(gca, 'FontSize', 18);
legend([legends{:}], {'contra sensorimotor', 'ipsi sensorimotor', 'central', 'frontal', 'occipital'}, 'Location', 'eastoutside', 'LineWidth', 1)