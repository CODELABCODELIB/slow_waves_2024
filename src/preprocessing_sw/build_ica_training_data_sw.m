function [EEG_train, overweight_segments] = build_ica_training_data_sw(EEG, event_onsets, options)
%% Build OPTICAT-style ICA training data (filter + overweight)
%
% **Usage:** [EEG_train, overweight_segments] = build_ica_training_data_sw(EEG, event_onsets)
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
%   - event_onsets = sample indices of EOG-proxy events (from detect_eog_events_sw)
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
%
% Requires:
%   - pop_eegfiltnew (EEGLAB)
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

fs = EEG_train.srate;
pre_samp = round(abs(options.pre_ms) / 1000 * fs);
post_samp = round(options.post_ms / 1000 * fs);

train_data = EEG_train.data;
n_chans = size(train_data, 1);
n_samps = size(train_data, 2);

overweight_segments = [];
n_events_used = 0;

for i = 1:length(event_onsets)
    onset = event_onsets(i);
    idx_start = onset - pre_samp;
    idx_end = onset + post_samp;

    if idx_start < 1 || idx_end > n_samps
        continue
    end

    seg = train_data(:, idx_start:idx_end);
    seg = seg - mean(seg, 2);
    overweight_segments = cat(3, overweight_segments, seg);
    n_events_used = n_events_used + 1;
end

fprintf('build_ica_training_data_sw: overweighted %d of %d detected events (edges excluded)\n', ...
    n_events_used, length(event_onsets));

if n_events_used > 0
    appended = reshape(overweight_segments, n_chans, []);
    train_data_overweighted = [train_data, appended];
else
    train_data_overweighted = train_data;
end

fprintf('build_ica_training_data_sw: training data length %d -> %d samples (%.2fx)\n', ...
    n_samps, size(train_data_overweighted, 2), size(train_data_overweighted, 2) / n_samps);

EEG_train.data = train_data_overweighted;
EEG_train.pnts = size(train_data_overweighted, 2);
EEG_train = eeg_checkset(EEG_train);

end
