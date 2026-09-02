function run_opticat_training_sw(path, options)
%% Run OPTICAT-style ICA training + variance-ratio sweep across .set files
%
% **Usage:** run_opticat_training_sw(path)
%   - run_opticat_training_sw(path, 'start_idx', 1, 'end_idx', 5)
%   - run_opticat_training_sw(path, 'save_plot', true)
%
% For each discovered .set file: loads it, trains ICA the OPTICAT way
% (train_ica_opticat_sw), computes the variance-ratio threshold sweep
% (compute_ic_variance_ratio_sw), and saves the resulting icaweights /
% icasphere / event onsets / variance-ratio table for later inspection,
% along with exploratory plots: one event-locked sanity plot per ocular
% event derivation (plot_ocular_event_snippets_sw), and per high-ratio
% IC, a scalp topography + event-locked activation plot (plot_ic_diagnostics_sw).
%
% This does NOT call pop_subcomp and does NOT run the rest of
% preprocess_EEG.m -- output is meant for inspection (choosing a
% threshold, spot-checking topographies) before wiring a chosen
% threshold into gettechnicallycleanEEG_sw.m as a follow-up step.
%
%  Input(s):
%   - path = path to raw data folders (passed to gen_set_file_names)
%   - options.start_idx **optional** double = start folder index (default 1)
%   - options.end_idx **optional** double = end folder index (default 0 = all)
%   - options.save_path_upper **optional** char = base path to save results under
%     (default '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/opticat_training')
%   - options.save_plot **optional** logical = save the average-overweighted-segment
%     sanity-check figure, per-derivation event plots, and per-IC topography/activation
%     plots per file (default true)
%   - options.hp_cutoff_hz / lp_hz / pre_ms / post_ms **optional** = passed through to
%     train_ica_opticat_sw
%   - options.target_srate / bandpass_hz / right_upper / right_lower / right_temporal /
%     left_upper / left_lower / left_temporal / blink_window_sec / threshold_factor /
%     min_blink_sec / merge_gap_sec **optional** = passed through to
%     train_ica_opticat_sw's ocular-event detector (detect_ocular_events_sw)
%   - options.thresholds / event_window_ms / quiet_buffer_ms **optional** = passed
%     through to compute_ic_variance_ratio_sw
%   - options.plot_pre_ms / plot_post_ms **optional** double = passed through to
%     plot_ocular_event_snippets_sw (default -300 / 300)
%   - options.ic_threshold **optional** double = passed through to
%     plot_ic_diagnostics_sw (default 1.1)
%   - options.ic_fallback_n **optional** double = passed through to
%     plot_ic_diagnostics_sw (default 5)
%   - options.ic_window_ms **optional** double (1,2) = passed through to
%     plot_ic_diagnostics_sw (default [-300 300])
%
%  Output(s):
%   - Saved per-file .mat files containing icaweights, icasphere, icachansind,
%     event_onsets, varratio_table
%   - Saved per-file sanity-check figures (if options.save_plot): the overweighted
%     training-window average, one plot per ocular event derivation, and one
%     topography+activation plot per high-ratio IC
%
% Requires:
%   - gen_set_file_names
%   - train_ica_opticat_sw
%   - compute_ic_variance_ratio_sw
%   - plot_ocular_event_snippets_sw
%   - plot_ic_diagnostics_sw
%
% Author: R.M.D. Kock, Leiden University

arguments
    path char;
    options.start_idx (1,1) double = 1;
    options.end_idx (1,1) double = 0;
    options.save_path_upper char = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/opticat_training';
    options.save_plot logical = true;
    options.hp_cutoff_hz (1,1) double = 2;
    options.lp_hz (1,1) double = 100;
    options.pre_ms (1,1) double = -20;
    options.post_ms (1,1) double = 10;
    options.target_srate (1,1) double = 250;
    options.bandpass_hz (1,2) double = [0.1 15];
    options.right_upper char = 'E35';
    options.right_lower char = 'E64';
    options.right_temporal char = 'E50';
    options.left_upper char = 'E49';
    options.left_lower char = 'E63';
    options.left_temporal char = 'E60';
    options.blink_window_sec (1,1) double = 0.5;
    options.threshold_factor (1,1) double = 6;
    options.min_blink_sec (1,1) double = 0.10;
    options.merge_gap_sec (1,1) double = 0.25;
    options.thresholds double = 0.5:0.1:1.6;
    options.event_window_ms (1,2) double = [-10 0];
    options.quiet_buffer_ms (1,1) double = 250;
    options.plot_pre_ms (1,1) double = -300;
    options.plot_post_ms (1,1) double = 300;
    options.ic_threshold (1,1) double = 1.1;
    options.ic_fallback_n (1,1) double = 5;
    options.ic_window_ms (1,2) double = [-300 300];
end

mkdir(options.save_path_upper)

[files_grouped, folder] = gen_set_file_names(path, options.start_idx, options.end_idx);

for i = 1:length(files_grouped)
    for j = 1:length(files_grouped{i})
        set_file = files_grouped{i}{j};
        fprintf('run_opticat_training_sw: processing %s/%s\n', folder{i}, set_file);

        EEG = pop_loadset(sprintf('%s/%s', folder{i}, set_file));

        [EEG, event_onsets, overweight_segments, derivation_onsets, filtered_data] = train_ica_opticat_sw(EEG, ...
            'hp_cutoff_hz', options.hp_cutoff_hz, ...
            'lp_hz', options.lp_hz, ...
            'pre_ms', options.pre_ms, ...
            'post_ms', options.post_ms, ...
            'target_srate', options.target_srate, ...
            'bandpass_hz', options.bandpass_hz, ...
            'right_upper', options.right_upper, ...
            'right_lower', options.right_lower, ...
            'right_temporal', options.right_temporal, ...
            'left_upper', options.left_upper, ...
            'left_lower', options.left_lower, ...
            'left_temporal', options.left_temporal, ...
            'blink_window_sec', options.blink_window_sec, ...
            'threshold_factor', options.threshold_factor, ...
            'min_blink_sec', options.min_blink_sec, ...
            'merge_gap_sec', options.merge_gap_sec);

        varratio_table = compute_ic_variance_ratio_sw(EEG, event_onsets, ...
            'thresholds', options.thresholds, ...
            'event_window_ms', options.event_window_ms, ...
            'quiet_buffer_ms', options.quiet_buffer_ms);

        [~, base_name] = fileparts(set_file);
        icaweights = EEG.icaweights; %#ok<NASGU>
        icasphere = EEG.icasphere; %#ok<NASGU>
        icachansind = EEG.icachansind; %#ok<NASGU>
        save(sprintf('%s/opticat_%s.mat', options.save_path_upper, base_name), ...
            'icaweights', 'icasphere', 'icachansind', 'event_onsets', 'varratio_table', '-v7.3')

        if options.save_plot && ~isempty(overweight_segments)
            fig = figure('Visible', 'off');
            avg_segment = mean(overweight_segments, 3);
            plot(avg_segment');
            title(sprintf('%s: average overweighted training window (-%gms/+%gms)', ...
                base_name, abs(options.pre_ms), options.post_ms), 'Interpreter', 'none');
            xlabel('Samples relative to event window start');
            ylabel('\muV');
            saveas(fig, sprintf('%s/opticat_%s_sanity.png', options.save_path_upper, base_name));
            close(fig);
        end

        if options.save_plot
            onsets_struct = derivation_onsets;
            onsets_struct.all = event_onsets;
            plot_ocular_event_snippets_sw(filtered_data, EEG.srate, onsets_struct, ...
                options.save_path_upper, base_name, ...
                'pre_ms', options.plot_pre_ms, 'post_ms', options.plot_post_ms);

            plot_ic_diagnostics_sw(EEG, varratio_table, event_onsets, ...
                options.save_path_upper, base_name, ...
                'threshold', options.ic_threshold, ...
                'fallback_n', options.ic_fallback_n, ...
                'window_ms', options.ic_window_ms);
        end
    end
end

end
