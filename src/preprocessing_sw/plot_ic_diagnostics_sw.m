function plot_ic_diagnostics_sw(EEG, varratio_table, event_onsets, save_dir, base_name, options)
%% Save scalp topography + event-locked activation plots for high-ratio ICs
%
% **Usage:** plot_ic_diagnostics_sw(EEG, varratio_table, event_onsets, save_dir, base_name)
%   - plot_ic_diagnostics_sw(..., 'threshold', 1.0, 'fallback_n', 8)
%
% For visual inspection only (no component removal): selects the components
% whose var_ratio exceeds options.threshold (Dimigen's reported value, 1.1, by
% default); if none exceed it, falls back to the top options.fallback_n
% components by var_ratio so there's always something to look at. For each
% selected component, saves one PNG with the scalp topography (from
% EEG.icawinv) next to the average event-locked component activation
% (from EEG.icaact, time-locked to event_onsets).
%
%  Input(s):
%   - EEG = EEGLAB struct with icaweights/icawinv/icachansind (and icaact, computed
%     if empty) already set, e.g. train_ica_opticat_sw's output
%   - varratio_table = output of compute_ic_variance_ratio_sw (columns: component, var_ratio, ...)
%   - event_onsets = merged ocular event onsets (sample indices), for activation plots
%   - save_dir = directory to save PNGs into (must already exist)
%   - base_name = filename prefix (e.g. the .set file's base name)
%   - options.threshold **optional** double = var_ratio cutoff for selecting
%     components to plot (default 1.1)
%   - options.fallback_n **optional** double = number of top-ranked components to
%     plot if none exceed options.threshold (default 5)
%   - options.window_ms **optional** double (1,2) = activation window relative to
%     event onset, ms (default [-300 300])
%
%  Output(s):
%   - Saved PNGs: <save_dir>/opticat_<base_name>_ic<NN>_topo.png, one per selected component
%
% Requires:
%   - extract_event_snippets_sw
%   - eeg_getdatact, topoplot (EEGLAB)
%
% Author: R.M.D. Kock, Leiden University

arguments
    EEG struct;
    varratio_table table;
    event_onsets double;
    save_dir char;
    base_name char;
    options.threshold (1,1) double = 1.1;
    options.fallback_n (1,1) double = 5;
    options.window_ms (1,2) double = [-300 300];
end

if isempty(EEG.icaact)
    EEG.icaact = eeg_getdatact(EEG, 'component', 1:size(EEG.icaweights, 1));
end

flagged = varratio_table(varratio_table.var_ratio > options.threshold, :);

if isempty(flagged)
    sorted = sortrows(varratio_table, 'var_ratio', 'descend');
    n = min(options.fallback_n, height(sorted));
    flagged = sorted(1:n, :);
    fprintf('plot_ic_diagnostics_sw: no components above threshold %.2f, falling back to top %d by var_ratio\n', ...
        options.threshold, n);
end

for i = 1:height(flagged)
    comp = flagged.component(i);
    ratio = flagged.var_ratio(i);

    [segments, n_used] = extract_event_snippets_sw(EEG.icaact(comp, :), event_onsets, ...
        EEG.srate, options.window_ms(1), options.window_ms(2), 'mean_center', false);

    fig = figure('Visible', 'off');

    subplot(1, 2, 1);
    topoplot(EEG.icawinv(:, comp), EEG.chanlocs(EEG.icachansind));
    title(sprintf('IC%d topography (ratio=%.2f)', comp, ratio));

    subplot(1, 2, 2);
    if n_used > 0
        avg_activation = mean(segments, 3);
        plot(squeeze(avg_activation));
        title(sprintf('Event-locked activation (n=%d)', n_used));
    else
        title('Event-locked activation (no usable events)');
    end
    xlabel('Samples relative to event window start');

    sgtitle(sprintf('%s: IC%d', base_name, comp), 'Interpreter', 'none');
    saveas(fig, sprintf('%s/opticat_%s_ic%02d_topo.png', save_dir, base_name, comp));
    close(fig);
end

end
