function [EEG, event_onsets, overweight_segments] = train_ica_opticat_sw(EEG, options)
%% Train ICA the OPTICAT way and back-project onto the original data
%
% **Usage:** [EEG, event_onsets, overweight_segments] = train_ica_opticat_sw(EEG)
%   - train_ica_opticat_sw(EEG, 'hp_cutoff_hz', 2.5)
%
% Orchestrates the adapted OPTICAT training steps (Dimigen et al., 2020,
% recommendations 1-3) and back-projects the resulting unmixing matrix
% onto the original unfiltered EEG struct, replacing whatever ICA
% weights were already present:
%   1. detect_eog_events_sw -- EOG-proxy (E63/E64) event onsets
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
%   - options.eog_threshold_sd **optional** double = passed to detect_eog_events_sw (default 4)
%   - options.eog_refractory_ms **optional** double = passed to detect_eog_events_sw (default 100)
%
%  Output(s):
%   - EEG = original EEG struct with new icaweights/icasphere/icaact/icachansind
%   - event_onsets = EOG-proxy event onsets used for overweighting (sample indices)
%   - overweight_segments = the mean-centered snippets appended during training,
%     for sanity-check plotting
%
% Requires:
%   - detect_eog_events_sw
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
    options.eog_threshold_sd (1,1) double = 4;
    options.eog_refractory_ms (1,1) double = 100;
end

[event_onsets, channel_counts] = detect_eog_events_sw(EEG, ...
    'threshold_sd', options.eog_threshold_sd, ...
    'refractory_ms', options.eog_refractory_ms);
fprintf('train_ica_opticat_sw: detected %d E63 / %d E64 events, %d merged\n', ...
    channel_counts.E63, channel_counts.E64, length(event_onsets));

[EEG_train, overweight_segments] = build_ica_training_data_sw(EEG, event_onsets, ...
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
