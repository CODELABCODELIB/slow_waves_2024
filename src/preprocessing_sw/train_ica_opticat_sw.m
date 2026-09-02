function [EEG, event_onsets, overweight_segments, derivation_onsets, filtered_data] = train_ica_opticat_sw(EEG, options)
%% Train ICA the OPTICAT way and back-project onto the original data
%
% **Usage:** [EEG, event_onsets, overweight_segments] = train_ica_opticat_sw(EEG)
%   - train_ica_opticat_sw(EEG, 'hp_cutoff_hz', 2.5)
%
% Orchestrates the adapted OPTICAT training steps (Dimigen et al., 2020,
% recommendations 1-3) and back-projects the resulting unmixing matrix
% onto the original unfiltered EEG struct, replacing whatever ICA
% weights were already present:
%   1. detect_ocular_events_sw -- per-eye vertical/horizontal EOG event onsets
%   2. build_ica_training_data_sw -- filter + overweight training data
%   3. pop_runica (extended Infomax) on the training data
%   4. copy icaweights/icasphere/icachansind back onto the original EEG
%      and recompute icaact via eeg_checkset (matches real OPTICAT's
%      back-projection in opticat_script.m)
%
%  Input(s):
%   - EEG = EEGLAB struct, raw/unfiltered continuous data (may already carry
%     an ICA solution -- it will be overwritten)
%   - options.hp_cutoff_hz **optional** double = passed to build_ica_training_data_sw (default 2)
%   - options.lp_hz **optional** double = passed to build_ica_training_data_sw (default 100)
%   - options.pre_ms / options.post_ms **optional** double = overweighting window (default -20/10)
%   - options.target_srate **optional** double = passed to detect_ocular_events_sw (default 250)
%   - options.bandpass_hz **optional** double (1,2) = passed to detect_ocular_events_sw (default [0.1 15])
%   - options.right_upper / right_lower / right_temporal **optional** char = passed to
%     detect_ocular_events_sw (default 'E35' / 'E64' / 'E50')
%   - options.left_upper / left_lower / left_temporal **optional** char = passed to
%     detect_ocular_events_sw (default 'E49' / 'E63' / 'E60')
%   - options.blink_window_sec **optional** double = passed to detect_ocular_events_sw (default 0.5)
%   - options.threshold_factor **optional** double = passed to detect_ocular_events_sw (default 6)
%   - options.min_blink_sec **optional** double = passed to detect_ocular_events_sw (default 0.10)
%   - options.merge_gap_sec **optional** double = passed to detect_ocular_events_sw (default 0.25)
%
%  Output(s):
%   - EEG = original EEG struct with new icaweights/icasphere/icaact/icachansind
%   - event_onsets = merged ocular event onsets used for overweighting (sample indices)
%   - overweight_segments = the mean-centered snippets appended during training,
%     for sanity-check plotting
%   - derivation_onsets = per-derivation onset sample indices (.right_vertical,
%     .left_vertical, .horizontal), for exploratory per-derivation plotting
%   - filtered_data = the HP(+LP)-filtered continuous data (before overweighting
%     was appended), same length/timing as the original EEG, for exploratory plotting
%
% Requires:
%   - detect_ocular_events_sw
%   - build_ica_training_data_sw
%   - pop_runica (EEGLAB)
%
% Author: R.M.D. Kock, Leiden University

arguments
    EEG struct;
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
end

[event_onsets, derivation_counts, derivation_onsets] = detect_ocular_events_sw(EEG, ...
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
fprintf('train_ica_opticat_sw: %d right_vertical, %d left_vertical, %d horizontal, %d merged\n', ...
    derivation_counts.right_vertical, derivation_counts.left_vertical, ...
    derivation_counts.horizontal, length(event_onsets));

[EEG_train, overweight_segments, filtered_data] = build_ica_training_data_sw(EEG, event_onsets, ...
    'hp_cutoff_hz', options.hp_cutoff_hz, ...
    'lp_hz', options.lp_hz, ...
    'pre_ms', options.pre_ms, ...
    'post_ms', options.post_ms);

chan_ind = 1:EEG.nbchan;
EEG_train = pop_runica(EEG_train, 'icatype', 'runica', 'extended', 1, ...
    'chanind', chan_ind, 'interrupt', 'off');

EEG.icaact = [];
EEG.icasphere = [];
EEG.icaweights = [];
EEG.icachansind = [];
EEG.icawinv = [];

EEG.icasphere = EEG_train.icasphere;
EEG.icaweights = EEG_train.icaweights;
EEG.icachansind = chan_ind;
EEG = eeg_checkset(EEG);

end
