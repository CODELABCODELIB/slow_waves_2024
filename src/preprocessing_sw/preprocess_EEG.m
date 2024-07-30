function [EEG] = preprocess_EEG(EEG)
%% Preprocess EEG for slow waves identification
%
% **Usage:**
%   - [EEG] = preprocess_EEG(EEG)
%
% Input(s):
%    EEG = EEGlab EEG struct format 
%
% Output(s):
%   EEG = processed EEG struct
%
% David Hoff, Leiden University
%
%% Band-pass filtering (0.5–48 Hz)
% Apply the filter
EEG = pop_eegfiltnew(EEG, 'locutoff', 0.5, 'hicutoff', 48);
%% Down-sampling to 128 Hz
% Down-sample the data
EEG = pop_resample(EEG, 128);
%% Re-referencing to the average of all channels
% Re-reference the EEG data to the average of all channels
EEG = pop_reref(EEG, []);
%% Re-referencing to the average of the mastoid electrodes
% Re-reference the EEG data to the average of the left and right mastoid electrodes
EEG = pop_reref(EEG, [52 58], 'keepref', 'on');
%% Low-pass filtering (< 4 Hz)
% Apply the filter
EEG = pop_eegfiltnew(EEG, 'locutoff', [], 'hicutoff', 4);
end

