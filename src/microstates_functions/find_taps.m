function [taps] = find_taps(EEG, indexes, options)
%% find tap indexes
%
% **Usage:**
%   - find_taps(taps)
%   - find_taps(..., indexes, {400 450 600})
%   - find_taps(..., 'tap_only', 0)
%
% Input(s):
%    EEG = EEG struct
%
% Optional input parameter(s):
%    indexes cell = latencies where tap sequences take place, if there are
%                   multiple gaps then the cell is of size (1 x number of gaps)
%    tap_only (default : 1) = if the EEG data has been truncated to fit
%
%
% Output(s):
%    taps = latencies a smartphone touchscreen interaction/tap took place (in ms)
%
% Ruchella Kock, Leiden University, 22/08/2023
%
arguments
    EEG;
    indexes = [];
    options.tap_only logical = 1;
end
if options.tap_only
    phone = [];
    for gap=1:length(indexes)
        tmp_dat = EEG.Aligned.BS_to_tap.Phone(:,indexes{gap});
        phone = [phone tmp_dat];
    end
    taps = [find(phone == 1)];
else
    taps = [find(EEG.Aligned.BS_to_tap.Phone == 1)];
end
end