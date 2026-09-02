function [segments, n_events_used] = extract_event_snippets_sw(data, event_onsets, srate, pre_ms, post_ms, options)
%% Cut mean-centered snippets around event onsets from a continuous data matrix
%
% **Usage:** [segments, n_events_used] = extract_event_snippets_sw(data, event_onsets, srate, pre_ms, post_ms)
%   - extract_event_snippets_sw(data, event_onsets, srate, -200, 200, 'mean_center', false)
%
% Generic snippet-cutting helper shared by build_ica_training_data_sw.m
% (overweighting) and the exploratory plotting functions (per-derivation and
% per-component sanity plots). For each onset, cuts a [-pre_ms +post_ms]
% window, optionally mean-centers each snippet along the time dimension, and
% skips events too close to the recording edges.
%
%  Input(s):
%   - data = [rows x samples] matrix (EEG channel data or ICA component activations)
%   - event_onsets = sample indices to center windows on
%   - srate = sampling rate of data, in Hz
%   - pre_ms = window start relative to onset, ms (negative = before onset)
%   - post_ms = window end relative to onset, ms
%   - options.mean_center **optional** logical = subtract each snippet's own mean
%     along the time dimension (default true)
%
%  Output(s):
%   - segments = [rows x window_samples x n_events_used] array of snippets
%   - n_events_used = number of onsets actually used (excludes edge-skipped ones)
%
% Author: R.M.D. Kock, Leiden University

arguments
    data double;
    event_onsets double;
    srate (1,1) double;
    pre_ms (1,1) double;
    post_ms (1,1) double;
    options.mean_center logical = true;
end

pre_samp = round(abs(pre_ms) / 1000 * srate);
post_samp = round(post_ms / 1000 * srate);
n_samps = size(data, 2);

segments = [];
n_events_used = 0;

for i = 1:length(event_onsets)
    onset = event_onsets(i);
    idx_start = onset - pre_samp;
    idx_end = onset + post_samp;

    if idx_start < 1 || idx_end > n_samps
        continue
    end

    seg = data(:, idx_start:idx_end);
    if options.mean_center
        seg = seg - mean(seg, 2);
    end
    segments = cat(3, segments, seg);
    n_events_used = n_events_used + 1;
end

end
