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
% icasphere / event onsets / variance-ratio table for later inspection.
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
%     sanity-check figure per file (default true)
%   - options.hp_cutoff_hz / lp_hz / pre_ms / post_ms **optional** = passed through to
%     train_ica_opticat_sw
%   - options.thresholds / event_window_ms / quiet_buffer_ms **optional** = passed
%     through to compute_ic_variance_ratio_sw
%
%  Output(s):
%   - Saved per-file .mat files containing icaweights, icasphere, icachansind,
%     event_onsets, varratio_table
%   - Saved per-file sanity-check figures (if options.save_plot)
%
% Requires:
%   - gen_set_file_names
%   - train_ica_opticat_sw
%   - compute_ic_variance_ratio_sw
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
    options.thresholds double = 0.5:0.1:1.6;
    options.event_window_ms (1,2) double = [-10 0];
    options.quiet_buffer_ms (1,1) double = 250;
end

mkdir(options.save_path_upper)

[files_grouped, folder] = gen_set_file_names(path, options.start_idx, options.end_idx);

for i = 1:length(files_grouped)
    for j = 1:length(files_grouped{i})
        set_file = files_grouped{i}{j};
        fprintf('run_opticat_training_sw: processing %s/%s\n', folder{i}, set_file);

        EEG = pop_loadset(sprintf('%s/%s', folder{i}, set_file));

        [EEG, event_onsets, overweight_segments] = train_ica_opticat_sw(EEG, ...
            'hp_cutoff_hz', options.hp_cutoff_hz, ...
            'lp_hz', options.lp_hz, ...
            'pre_ms', options.pre_ms, ...
            'post_ms', options.post_ms);

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
            title(sprintf('%s: average overweighted segment', base_name), 'Interpreter', 'none');
            xlabel('Samples relative to event window start');
            ylabel('\muV');
            saveas(fig, sprintf('%s/opticat_%s_sanity.png', options.save_path_upper, base_name));
            close(fig);
        end
    end
end

end
