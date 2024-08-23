function h = create_topoplot(data, EEG, cmap,tf,lims,number_timestamps,real_timestamps,save_results, path, i_path)
arguments
    data;
    EEG struct;
    cmap ;
    tf logical;
    lims double = [];
    number_timestamps double = [];
    real_timestamps double = [];
    save_results logical = 0;
    path char = '';
    i_path char = '';
end
if isempty(lims)
    lims = [min(data(:)) max(data(:))];
    highest = round(max(abs(lims(1)), abs(lims(2))), 2);
    lims = [-highest highest];
end
color = colormap(cmap);
if strcmp(cmap, 'cool')
    color(256/2-5:256/2+5,:) = 1;
% color(1:10,:) = 1;
    colormap(color)
end


caxis(lims)
if isempty(number_timestamps)
    real_timestamps = [-750 -500 -250 -50 0 50 250 500 750];
%     real_timestamps = [-750 -500 -250 -50 0];
%     real_timestamps = [0 250 500 750 900];
    number_timestamps = real_timestamps+(size(data,2)/2);
end
if tf
%     number_timestamps = [57 71 89 100 112 130 144];
number_timestamps = [57 71 89 95 97 100 104 106 112 130 144];
end
h = figure;
tiledlayout(3, length(number_timestamps)+1);

for j=1:length(number_timestamps)
    nexttile(j, [3 1])
    topoplot([squeeze(data(:,number_timestamps(j)))], EEG.chanlocs,'style', 'both' , 'whitebk', 'on', 'electrodes', 'off', 'maplimits', lims, 'colormap', color);
    title(real_timestamps(j))
    set(gcf,'color', 'white')
end
% colorbar('Location', 'east');
nexttile((length(number_timestamps)+1)*2)
tmp_imsc = imagesc([1:200], [1:40], lims);
set(gca, 'Visible', 'off')
set(tmp_imsc, 'AlphaData', lims .* 0)
colorbar('Location', 'west', 'limits', lims);
set(gca, 'Visible', 'off');
sgtitle(sprintf('%s', i_path))

set(h, 'Units', 'Inches');
pos = get(h, 'Position');
set(h, 'PaperPositionMode', 'Auto', 'PaperUnits', 'Inches', 'PaperSize', [pos(3), pos(4)])

if (save_results)
    print(h, sprintf('%s/%s.pdf', path, i_path), '-dpdf', '-r0')
    saveas(h, sprintf('%s/%s.svg', path, i_path))
end
end