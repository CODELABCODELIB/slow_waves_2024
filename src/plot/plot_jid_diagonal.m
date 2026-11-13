function [summary] = plot_jid_diagonal(feature_jid, chanlocs, Orignalchanlocs, name, save_dir, options)
%% Population summary of the JID diagonal (steady rhythms, fast -> slow) of one feature
%
% **Usage:**
%   - plot_jid_diagonal(rate, EEG.chanlocs, EEG.Orignalchanlocs, 'rate', save_dir)
%   - plot_jid_diagonal(... , 'ylabel', 'log10 rate', 'data_dir', plot_data_dir)
%
% Input(s):
%    feature_jid = cell {participant x channel} of 50x50 JIDs
%    chanlocs = channel locations of the analysed channels (topoplots)
%    Orignalchanlocs = original channel locations (8x8 grid order, as population_sw_to_behavior_plots)
%    name = feature name used in the file names
%    save_dir = folder for the figures
%
% Optional input parameter(s):
%    - ylabel (Default name) = label of the feature values
%    - min_bins (Default 5) = minimal number of filled diagonal bins per participant/channel
%    - data_dir (Default []) = if given, <data_dir>/<name>_diagonal.mat is saved
%
% Figures (in save_dir):
%   <name>_diag_slope_topo.svg       trimmed mean (20%) over participants of the diagonal slope
%   <name>_diag_absderiv_topo.svg    trimmed mean of the mean absolute derivative along the diagonal
%   <name>_diag_profiles_grid.svg    diagonal profile per channel (8x8 grid), trimmed mean +- SEM
%   <name>_diag_profile_allchans.svg channel-averaged diagonal per participant + trimmed mean +- SEM
%   <name>_diag_heatmap.svg          channel x diagonal bin, trimmed mean over participants
%
arguments
    feature_jid cell;
    chanlocs;
    Orignalchanlocs;
    name char;
    save_dir char;
    options.ylabel = name;
    options.min_bins = 5;
    options.data_dir = [];
end
if ~exist(save_dir,'dir'); mkdir(save_dir); end
[diag_vals, slope, abs_deriv, gridx] = jid_diagonal_summary(feature_jid, 'min_bins', options.min_bins);
n_chans = min(size(feature_jid,2), numel(chanlocs));
diag_vals = diag_vals(:,1:n_chans,:);
slope = slope(:,1:n_chans);
abs_deriv = abs_deriv(:,1:n_chans);
n_bins = numel(gridx);
% population values per channel
pop_slope = nan_trimmean(slope);
pop_abs_deriv = nan_trimmean(abs_deriv);
pop_diag = reshape(nan_trimmean(reshape(diag_vals, size(diag_vals,1), [])), n_chans, n_bins);
sem_diag = reshape(nan_sem(reshape(diag_vals, size(diag_vals,1), [])), n_chans, n_bins);
n_pp_slope = sum(any(~isnan(slope),2));
fprintf('JID diagonal %s: %d participants with a slope, %d/%d channels with a population slope\n', ...
    name, n_pp_slope, sum(~isnan(pop_slope)), n_chans);
% x axis ticks in seconds
tick_ms = [0.1 1 10 100]*1000;
tick_labels = {'0.1','1','10','100'};
%% topoplot slope (blue-white-red, symmetric)
half = 128;
bwr = [linspace(0,1,half)', linspace(0,1,half)', ones(half,1); ...
    ones(half,1), linspace(1,0,half)', linspace(1,0,half)'];
lim = max(abs(pop_slope), [], 'omitnan');
if isempty(lim) || isnan(lim) || lim == 0; lim = 1; end
diag_topo(pop_slope, chanlocs(1:n_chans), [-lim lim], bwr, ...
    sprintf('%s: diagonal slope (n = %d)', name, n_pp_slope), ...
    sprintf('%s per log_{10} ms', options.ylabel), ...
    sprintf('%s/%s_diag_slope_topo.svg', save_dir, name));
%% topoplot mean absolute derivative
lim = max(pop_abs_deriv, [], 'omitnan');
if isempty(lim) || isnan(lim) || lim == 0; lim = 1; end
diag_topo(pop_abs_deriv, chanlocs(1:n_chans), [0 lim], parula(256), ...
    sprintf('%s: mean |derivative| along diagonal (n = %d)', name, n_pp_slope), ...
    sprintf('|\\Delta %s| per log_{10} ms', options.ylabel), ...
    sprintf('%s/%s_diag_absderiv_topo.svg', save_dir, name));
%% diagonal profile per channel, 8x8 grid
lo = pop_diag - sem_diag; hi = pop_diag + sem_diag;
lo(isnan(lo)) = pop_diag(isnan(lo)); hi(isnan(hi)) = pop_diag(isnan(hi));
y_lims = [min(lo(:),[],'omitnan'), max(hi(:),[],'omitnan')];
if any(isnan(y_lims)) || y_lims(1) == y_lims(2); y_lims = []; end
h = figure('Position',[50 50 1400 1400]);
tiledlayout(8,8, 'TileSpacing','compact')
sorted_idx = sort_electrodes(Orignalchanlocs);
for chan=sorted_idx
    nexttile;
    if chan > n_chans || all(isnan(pop_diag(chan,:)))
        axis off;
        continue
    end
    shaded_line(gridx, pop_diag(chan,:), sem_diag(chan,:), [0 0.447 0.741]);
    xlim(gridx([1 end]))
    if ~isempty(y_lims); ylim(y_lims); end
    xticks(log10(tick_ms)); xticklabels({}); yticklabels({});
    box off;
    title(chanlocs(chan).labels, 'FontSize', 8)
end
sgtitle(sprintf('%s along the JID diagonal (x: 0.1-100 s, log scale; y: %s %s)', name, ...
    options.ylabel, mat2str(round(y_lims,3))), 'Interpreter', 'none')
saveas(h, sprintf('%s/%s_diag_profiles_grid.svg', save_dir, name))
close(h)
%% channel-averaged diagonal per participant
pp_diag = reshape(mean(diag_vals, 2, 'omitnan'), size(diag_vals,1), n_bins); % participant x bins
h = figure;
hold on
for pp=1:size(pp_diag,1)
    plot(gridx, pp_diag(pp,:), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
end
shaded_line(gridx, nan_trimmean(pp_diag), nan_sem(pp_diag), [0 0 0]);
hold off
xlim(gridx([1 end]))
xticks(log10(tick_ms)); xticklabels(tick_labels);
xlabel('interval along the diagonal (s)'); ylabel(options.ylabel);
title(sprintf('%s: JID diagonal, mean over channels (n = %d)', name, sum(any(~isnan(pp_diag),2))), 'Interpreter', 'none')
box off;
saveas(h, sprintf('%s/%s_diag_profile_allchans.svg', save_dir, name))
close(h)
%% heatmap channel x diagonal bin
heat_idx = sorted_idx(sorted_idx <= n_chans);
h = figure('Position',[100 100 700 900]);
im = imagesc(gridx, 1:numel(heat_idx), pop_diag(heat_idx,:));
set(im, 'AlphaData', ~isnan(pop_diag(heat_idx,:)))
colormap(gca, 'jet'); cb = colorbar; ylabel(cb, options.ylabel);
xticks(log10(tick_ms)); xticklabels(tick_labels);
yticks(1:numel(heat_idx)); yticklabels({chanlocs(heat_idx).labels});
set(gca, 'FontSize', 6, 'TickLength', [0 0])
xlabel('interval along the diagonal (s)', 'FontSize', 10); ylabel('channel (grid order)', 'FontSize', 10);
title(sprintf('%s: JID diagonal per channel', name), 'Interpreter', 'none', 'FontSize', 10)
box off;
saveas(h, sprintf('%s/%s_diag_heatmap.svg', save_dir, name))
close(h)
%% data
summary = struct('diag_vals', diag_vals, 'slope', slope, 'abs_deriv', abs_deriv, 'gridx', gridx, ...
    'pop_diag', pop_diag, 'pop_slope', pop_slope, 'pop_abs_deriv', pop_abs_deriv, ...
    'channel_labels', {{chanlocs(1:n_chans).labels}});
if ~isempty(options.data_dir)
    if ~exist(options.data_dir,'dir'); mkdir(options.data_dir); end
    save(sprintf('%s/%s_diagonal.mat', options.data_dir, name), '-struct', 'summary', '-v7.3')
end
end

function diag_topo(values, chanlocs, lims, cmap, title_str, cbar_label, save_file)
% topoplot of the channels with a value (topoplot does not accept NaN channels)
ok = ~isnan(values);
h = figure;
if sum(ok) >= 3
    topoplot(values(ok), chanlocs(ok), 'maplimits', lims, 'style', 'map', 'electrodes', 'off', 'colormap', cmap);
    colormap(gca, cmap); clim(lims);
    cb = colorbar; ylabel(cb, cbar_label);
else
    axis off; text(0.5, 0.5, 'too few channels with data', 'HorizontalAlignment', 'center');
end
title(title_str, 'Interpreter', 'none')
saveas(h, save_file)
close(h)
end

function shaded_line(x, m, s, color)
% mean line with +- SEM shading, drawn per contiguous segment of finite values
s(isnan(s)) = 0;
ok = ~isnan(m);
starts = find(diff([0 ok]) == 1);
stops = find(diff([ok 0]) == -1);
was_hold = ishold; hold on
for k=1:numel(starts)
    i = starts(k):stops(k);
    fill([x(i) fliplr(x(i))], [m(i)+s(i) fliplr(m(i)-s(i))], color, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
    plot(x(i), m(i), 'Color', color, 'LineWidth', 1.5);
end
if ~was_hold; hold off; end
end

function m = nan_trimmean(x)
% 20% trimmed mean per column, ignoring NaN (as population_sw_to_behavior_plots)
m = nan(1, size(x,2));
for j=1:size(x,2)
    v = x(~isnan(x(:,j)), j);
    if ~isempty(v); m(j) = trimmean(v, 20); end
end
end

function s = nan_sem(x)
% standard error per column, ignoring NaN
n = sum(~isnan(x), 1);
s = std(x, 0, 1, 'omitnan') ./ sqrt(n);
s(n < 2) = NaN;
end
