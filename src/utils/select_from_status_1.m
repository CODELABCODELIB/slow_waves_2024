function [selected_1] = select_from_status_1(eeg_name)
%% Select participants with EEG and phone data and select only first file for curfew participants
%
% **Usage:** [selected_1] = select_from_status_1(eeg_name)
%
%  Input(s):
%   - eeg_name = struct based on status.mat file containing meta data of
%   the EEG measurement. Specifically whether Phone or EEG data is present.
%   Whether participant is a curfew participant. 
%
%  Output(s):
%   - selected_1 = file names for selected participants
%
% Author: R.M.D. Kock

if ~isfield(eeg_name, 'datediff')
    [eeg_name] = calculate_date_differences(eeg_name);
end
% select participants with EEG, 
% Phone data
% If curfew participants only select the first file
selected_1 = {eeg_name([eeg_name.EEG] == 1 & [eeg_name.Phone] == 1 & (~[eeg_name.CurfewExp] | ~[eeg_name.datediff])).processed_name};
end