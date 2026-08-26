function [event_onsets, channel_counts] = detect_eog_events_sw(EEG, options)
%% Detect blink/saccade-proxy events on the infraorbital EOG-proxy channels
%
% **Usage:** [event_onsets, channel_counts] = detect_eog_events_sw(EEG)
%   - detect_eog_events_sw(EEG, 'threshold_sd', 4)
%
% Detects threshold-crossing deflections independently on channels E63
% and E64 (the same EOG-proxy channels already used by icablinkmetrics
% in gettechnicallycleanEEG_sw.m), using a robust (MAD-based) z-score
% peak detector. Onsets from both channels are merged into a single
% sorted list, deduplicating events that fall within a refractory
% window of each other.
%
% No eye-tracker is available for this montage, so this is a coarse
% proxy for saccade/blink onset timing, not ground truth.
%
%  Input(s):
%   - EEG = EEGLAB struct, raw/unfiltered continuous data
%   - options.threshold_sd **optional** double = robust z-score threshold for
%     peak detection (default 4)
%   - options.refractory_ms **optional** double = minimum spacing between
%     merged events, in ms (default 100)
%
%  Output(s):
%   - event_onsets = sorted vector of sample indices for merged EOG events
%   - channel_counts = struct with .E63 and .E64 raw (pre-merge) event counts
%
% Author: R.M.D. Kock, Leiden University

arguments
    EEG struct;
    options.threshold_sd (1,1) double = 4;
    options.refractory_ms (1,1) double = 100;
end

chan_idx = find(strcmp({EEG.chanlocs.labels}, 'E63') | strcmp({EEG.chanlocs.labels}, 'E64'));
if isempty(chan_idx)
    error('detect_eog_events_sw:noChannels', 'Could not find E63/E64 channels in EEG.chanlocs');
end

refractory_samp = round(options.refractory_ms / 1000 * EEG.srate);

raw_onsets = [];
channel_counts = struct();
for i = 1:length(chan_idx)
    label = EEG.chanlocs(chan_idx(i)).labels;
    sig = double(EEG.data(chan_idx(i), :));
    onsets = local_threshold_peaks(sig, options.threshold_sd, refractory_samp);
    channel_counts.(label) = length(onsets);
    raw_onsets = [raw_onsets, onsets]; %#ok<AGROW>
end

event_onsets = unique(sort(raw_onsets));
event_onsets = local_merge_refractory(event_onsets, refractory_samp);

end

function onsets = local_threshold_peaks(sig, threshold_sd, refractory_samp)
% robust (MAD-based) z-score peak detector on the rectified signal derivative
d = [0, diff(sig)];
med = median(d);
mad_val = median(abs(d - med));
robust_sd = 1.4826 * mad_val;
if robust_sd == 0
    onsets = [];
    return
end
z = (d - med) / robust_sd;
above = abs(z) > threshold_sd;
onset_candidates = find(diff([0, above]) == 1);
onsets = local_merge_refractory(onset_candidates, refractory_samp);
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
