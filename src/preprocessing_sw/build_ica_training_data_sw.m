function [EEG_train, overweight_segments, filtered_data] = build_ica_training_data_sw(EEG, event_onsets, options)
%% Build OPTICAT-style ICA training data (filter + overweight)
%
% **Usage:** [EEG_train, overweight_segments, filtered_data] = build_ica_training_data_sw(EEG, event_onsets)
%   - build_ica_training_data_sw(..., 'hp_cutoff_hz', 2.5)
%
% Adapts Dimigen et al.'s (2020) OPTICAT training-data recommendations:
%   1. High-pass filter at a ~2 Hz passband edge (pop_eegfiltnew), matching
%      the default in the reference OPTICAT opticat_script.m.
%   2. Leave low-pass open (skip low-pass unless the data isn't already
%      band-limited near 100 Hz) -- real OPTICAT assumes this is already
%      done upstream, this function checks EEG.srate instead of assuming it.
%   3. Overweight peri-event samples: cut a [-20 +10] ms window around each
%      event onset, mean-center each snippet per-channel, and append all
%      snippets to the filtered continuous data. This matches the exact
%      window used by real OPTICAT's pop_overweightevents(EEG,'saccade',
%      [-0.02 0.01], ...), but appends one snippet per detected event rather
%      than targeting a fixed proportion of total training-data length
%      (real OPTICAT's OW_FACTOR) -- see plan notes on this simplification.
%
%  Input(s):
%   - EEG = EEGLAB struct, raw/unfiltered continuous data
%   - event_onsets = sample indices of ocular events (from detect_ocular_events_sw)
%   - options.hp_cutoff_hz **optional** double = high-pass passband edge (default 2)
%   - options.lp_hz **optional** double = low-pass passband edge, only applied if
%     EEG.srate/2 exceeds this (default 100)
%   - options.pre_ms **optional** double = window start relative to onset, ms (default -20)
%   - options.post_ms **optional** double = window end relative to onset, ms (default 10)
%
%  Output(s):
%   - EEG_train = EEGLAB struct with filtered + overweighted continuous data, ready for pop_runica
%   - overweight_segments = [chans x samples x events] array of the mean-centered
%     snippets that were appended, for sanity-check plotting by the caller
%   - filtered_data = [chans x samples] the filtered (HP + optional LP) data BEFORE
%     the overweighted snippets were appended -- same length/timing as the original
%     EEG, useful for exploratory plotting keyed to the original event onsets
%
% Requires:
%   - pop_eegfiltnew (EEGLAB)
%   - extract_event_snippets_sw
%
% Author: R.M.D. Kock, Leiden University

arguments
    EEG struct;
    event_onsets double;
    options.hp_cutoff_hz (1,1) double = 2;
    options.lp_hz (1,1) double = 100;
    options.pre_ms (1,1) double = -20;
    options.post_ms (1,1) double = 10;
end

EEG_train = pop_eegfiltnew(EEG, options.hp_cutoff_hz, []);

if EEG_train.srate / 2 > options.lp_hz
    EEG_train = pop_eegfiltnew(EEG_train, [], options.lp_hz);
end

filtered_data = EEG_train.data;
n_samps = size(filtered_data, 2);

[overweight_segments, n_events_used] = extract_event_snippets_sw(filtered_data, event_onsets, ...
    EEG_train.srate, options.pre_ms, options.post_ms);

fprintf('build_ica_training_data_sw: overweighted %d of %d detected events (edges excluded)\n', ...
    n_events_used, length(event_onsets));

if n_events_used > 0
    n_chans = size(filtered_data, 1);
    appended = reshape(overweight_segments, n_chans, []);
    train_data_overweighted = [filtered_data, appended];
else
    train_data_overweighted = filtered_data;
end

fprintf('build_ica_training_data_sw: training data length %d -> %d samples (%.2fx)\n', ...
    n_samps, size(train_data_overweighted, 2), size(train_data_overweighted, 2) / n_samps);

EEG_train.data = train_data_overweighted;
EEG_train.pnts = size(train_data_overweighted, 2);
EEG_train = eeg_checkset(EEG_train);

end
