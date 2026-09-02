function [event_onsets, derivation_counts, derivation_onsets] = detect_ocular_events_sw(EEG, options)
%% Detect ocular events from per-eye vertical EOG + a standard bilateral horizontal EOG
%
% **Usage:** [event_onsets, derivation_counts] = detect_ocular_events_sw(EEG)
%   - detect_ocular_events_sw(EEG, 'threshold_factor', 5)
%
% Extends the blink-detection logic validated in src/playground/blink_exploration.m
% from one averaged vertical EOG into 3 derivations, using a confirmed montage
% mapping:
%   right_vertical = right_upper    - right_lower     (e.g. E35 - E64)
%   left_vertical  = left_upper     - left_lower      (e.g. E49 - E63)
%   horizontal     = right_temporal - left_temporal   (e.g. E50 - E60)
%
% The horizontal derivation is the standard bilateral HEOG approach (right
% temporal/canthus electrode minus left temporal/canthus electrode), capturing
% the corneo-retinal dipole swinging left-right during saccades -- unlike an
% earlier per-side temporal-minus-infraorbital version, this is a recognized
% textbook HEOG formula, not an ad hoc contrast.
%
% Detection runs on one shared resampled + band-passed copy of the data (does
% not modify EEG.data). Each of the 3 derivations is thresholded independently
% with the same moving-window peak-to-peak / robust-MAD-threshold algorithm,
% cleaned up (short events dropped, close events merged), then all 3
% derivations' onsets are pooled and refractory-merged into one combined list.
% Onset/offset times are converted back to sample indices in the ORIGINAL
% EEG.srate, since that is the resolution needed downstream (e.g.
% build_ica_training_data_sw.m's overweighting window).
%
%  Input(s):
%   - EEG = EEGLAB struct, raw/unfiltered continuous data
%   - options.target_srate **optional** double = sampling rate for the detection
%     copy (default 250)
%   - options.bandpass_hz **optional** double (1,2) = band-pass filter edges for the
%     detection copy (default [0.1 15])
%   - options.right_upper / right_lower / right_temporal **optional** char = right-eye
%     channel labels (default 'E35' / 'E64' / 'E50')
%   - options.left_upper / left_lower / left_temporal **optional** char = left-eye
%     channel labels (default 'E49' / 'E63' / 'E60')
%   - options.blink_window_sec **optional** double = moving-window length for
%     peak-to-peak amplitude (default 0.5)
%   - options.threshold_factor **optional** double = robust threshold multiplier,
%     median + threshold_factor*MAD (default 6)
%   - options.min_blink_sec **optional** double = discard events shorter than this
%     (default 0.10)
%   - options.merge_gap_sec **optional** double = merge events separated by less
%     than this, both within a derivation and across derivations (default 0.25)
%
%  Output(s):
%   - event_onsets = merged sample indices (in the original EEG.srate) of detected
%     ocular events, pooled across all 3 derivations
%   - derivation_counts = struct with per-derivation raw (pre-merge) event counts
%     (.right_vertical, .left_vertical, .horizontal)
%   - derivation_onsets = struct with per-derivation raw (pre-merge) onset sample
%     indices, in the original EEG.srate (same field names as derivation_counts) --
%     useful for exploratory plotting of each derivation's own events separately
%
% Requires:
%   - pop_resample, pop_eegfiltnew (EEGLAB)
%
% Author: R.M.D. Kock, Leiden University

arguments
    EEG struct;
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

EEG_det = EEG;
if EEG_det.srate > options.target_srate
    EEG_det = pop_resample(EEG_det, options.target_srate);
end
EEG_det = pop_eegfiltnew(EEG_det, options.bandpass_hz(1), options.bandpass_hz(2));
det_srate = EEG_det.srate;

right_upper_idx = local_find_channel(EEG_det, options.right_upper);
right_lower_idx = local_find_channel(EEG_det, options.right_lower);
right_temporal_idx = local_find_channel(EEG_det, options.right_temporal);
left_upper_idx = local_find_channel(EEG_det, options.left_upper);
left_lower_idx = local_find_channel(EEG_det, options.left_lower);
left_temporal_idx = local_find_channel(EEG_det, options.left_temporal);

derivation_names = {'right_vertical', 'left_vertical', 'horizontal'};
derivation_signals = {
    EEG_det.data(right_upper_idx, :) - EEG_det.data(right_lower_idx, :), ...
    EEG_det.data(left_upper_idx, :) - EEG_det.data(left_lower_idx, :), ...
    EEG_det.data(right_temporal_idx, :) - EEG_det.data(left_temporal_idx, :)
};

merge_gap_samples_det = round(options.merge_gap_sec * det_srate);
merge_gap_samples_orig = round(options.merge_gap_sec * EEG.srate);

derivation_counts = struct();
derivation_onsets = struct();
all_onsets_orig = [];

for d = 1:length(derivation_names)
    name = derivation_names{d};
    starts = local_detect_events(derivation_signals{d}, det_srate, ...
        options.blink_window_sec, options.threshold_factor, ...
        options.min_blink_sec, merge_gap_samples_det);

    starts_orig = round(starts / det_srate * EEG.srate);

    derivation_counts.(name) = length(starts_orig);
    derivation_onsets.(name) = starts_orig;
    all_onsets_orig = [all_onsets_orig, starts_orig]; %#ok<AGROW>

    fprintf('detect_ocular_events_sw: %s -> %d events\n', name, length(starts_orig));
end

event_onsets = local_merge_refractory(sort(all_onsets_orig), merge_gap_samples_orig);

end

function idx = local_find_channel(EEG, label)
idx = find(strcmp({EEG.chanlocs.labels}, label));
if isempty(idx)
    error('detect_ocular_events_sw:missingChannel', 'Could not find channel %s in EEG.chanlocs', label);
end
idx = idx(1);
end

function starts = local_detect_events(signal, srate, window_sec, threshold_factor, min_event_sec, merge_gap_samples)

window_samples = round(window_sec * srate);
moving_max = movmax(signal, window_samples);
moving_min = movmin(signal, window_samples);
moving_range = moving_max - moving_min;

range_median = median(moving_range, 'omitnan');
range_mad = mad(moving_range, 1);
threshold = range_median + threshold_factor * range_mad;

event_mask = moving_range > threshold;

min_event_samples = round(min_event_sec * srate);

event_diff = diff([false, event_mask, false]);
event_starts = find(event_diff == 1);
event_ends = find(event_diff == -1) - 1;

durations = event_ends - event_starts + 1;
keep = durations >= min_event_samples;
event_starts = event_starts(keep);
event_ends = event_ends(keep);

if isempty(event_starts)
    starts = [];
    return
end

merged_starts = event_starts(1);
merged_ends = event_ends(1);
for i = 2:length(event_starts)
    gap = event_starts(i) - merged_ends(end);
    if gap <= merge_gap_samples
        merged_ends(end) = event_ends(i);
    else
        merged_starts(end+1) = event_starts(i); %#ok<AGROW>
        merged_ends(end+1) = event_ends(i); %#ok<AGROW>
    end
end

starts = merged_starts;

end

function merged = local_merge_refractory(onsets, refractory_samp)
merged = [];
last = -inf;
for i = 1:length(onsets)
    if onsets(i) - last > refractory_samp
        merged = [merged, onsets(i)]; %#ok<AGROW>
        last = onsets(i);
    end
end
end
