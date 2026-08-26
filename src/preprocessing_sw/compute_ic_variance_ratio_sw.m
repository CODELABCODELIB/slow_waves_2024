function varratio_table = compute_ic_variance_ratio_sw(EEG, event_onsets, options)
%% Sweep variance-ratio thresholds for ocular component classification
%
% **Usage:** varratio_table = compute_ic_variance_ratio_sw(EEG, event_onsets)
%   - compute_ic_variance_ratio_sw(EEG, event_onsets, 'thresholds', 0.5:0.1:1.6)
%
% Adapted version of the variance-ratio ocular-component test used by real
% OPTICAT's pop_eyetrackerica (Plochl et al., 2012; Dimigen, 2020). That
% function hard-requires genuine eye-tracker 'saccade'/'fixation' events and
% has no generic-window fallback -- since no eye-tracker is available here,
% this reimplements the ratio using:
%   - "event" windows: options.event_window_ms around each EOG-proxy onset
%     (default [-10 0] ms, matching real OPTICAT's SACC_WINDOW = [5 0] samples)
%   - "quiet" windows (fixation proxy): samples farther than
%     options.quiet_buffer_ms from ANY detected event onset
% This is a necessary proxy for genuine fixation ground truth, not a
% like-for-like reimplementation -- treat results as exploratory.
%
% No component removal happens here (no pop_subcomp) -- this only reports,
% for a swept range of thresholds, which components would be flagged, so a
% threshold can be chosen by inspection before committing to removal.
%
%  Input(s):
%   - EEG = EEGLAB struct with icaact already computed (post back-projection,
%     e.g. output of train_ica_opticat_sw)
%   - event_onsets = EOG-proxy event onsets (sample indices)
%   - options.thresholds **optional** double vector = variance-ratio thresholds to
%     sweep (default 0.5:0.1:1.6, matching the real OPTICAT paper-pipeline sweep;
%     1.1 is Dimigen's single reported value)
%   - options.event_window_ms **optional** double (1,2) = window relative to onset
%     counted as "event" variance (default [-10 0])
%   - options.quiet_buffer_ms **optional** double = minimum distance from any event
%     onset for a sample to count as "quiet" (default 250)
%
%  Output(s):
%   - varratio_table = table with columns: component, var_ratio, then one logical
%     column per swept threshold (flagged_<threshold>) indicating whether that
%     component would be classified as ocular at that threshold
%
% Author: R.M.D. Kock, Leiden University

arguments
    EEG struct;
    event_onsets double;
    options.thresholds double = 0.5:0.1:1.6;
    options.event_window_ms (1,2) double = [-10 0];
    options.quiet_buffer_ms (1,1) double = 250;
end

if isempty(EEG.icaact)
    EEG.icaact = eeg_getdatact(EEG, 'component', 1:size(EEG.icaweights, 1));
end

fs = EEG.srate;
n_samps = size(EEG.icaact, 2);
n_comps = size(EEG.icaact, 1);

pre_samp = round(options.event_window_ms(1) / 1000 * fs);
post_samp = round(options.event_window_ms(2) / 1000 * fs);
buffer_samp = round(options.quiet_buffer_ms / 1000 * fs);

event_mask = false(1, n_samps);
quiet_mask = true(1, n_samps);
for i = 1:length(event_onsets)
    onset = event_onsets(i);

    e_start = max(1, onset + pre_samp);
    e_end = min(n_samps, onset + post_samp);
    if e_start <= e_end
        event_mask(e_start:e_end) = true;
    end

    q_start = max(1, onset - buffer_samp);
    q_end = min(n_samps, onset + buffer_samp);
    quiet_mask(q_start:q_end) = false;
end
quiet_mask = quiet_mask & ~event_mask;

if ~any(event_mask)
    error('compute_ic_variance_ratio_sw:noEventSamples', 'No valid event windows found');
end
if ~any(quiet_mask)
    error('compute_ic_variance_ratio_sw:noQuietSamples', 'No valid quiet windows found -- try a smaller quiet_buffer_ms');
end

var_ratio = nan(n_comps, 1);
for c = 1:n_comps
    event_var = var(EEG.icaact(c, event_mask));
    quiet_var = var(EEG.icaact(c, quiet_mask));
    var_ratio(c) = event_var / quiet_var;
end

varratio_table = table((1:n_comps)', var_ratio, 'VariableNames', {'component', 'var_ratio'});
for t = 1:length(options.thresholds)
    thresh = options.thresholds(t);
    col_name = sprintf('flagged_%s', strrep(sprintf('%.1f', thresh), '.', '_'));
    varratio_table.(col_name) = var_ratio > thresh;
end

end
