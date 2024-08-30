function [EEG,indexes] = prepare_EEG_w_taps_only(EEG)
%% Prepare EEG with tap sequences only
%  (remove resting state movie or smartphone box/forcesensor data)
%
% **Usage:**
%   - prepare_EEG_w_taps_only(EEG)
%
% Input(s):
%    EEG = EEG struct
%
% Output(s):
%    EEG = truncated EEG struct
%    indexes cell = latencies where tap sequences take place, if there are
%                   multiple gaps then the cell is of size (1 x number of gaps)
%
% Ruchella Kock, Leiden University, 22/08/2023
%%
% find indexes/latencies of the ALIGNED smartphone taps
latencies = [EEG.event.latency];
taps = latencies(strcmp({EEG.event.type}, 'pt'));
EEG.Aligned.BS_to_tap.Phone = zeros(size(EEG.data(1,:)));
EEG.Aligned.BS_to_tap.Phone(taps) = 1;
% taps = [find(EEG.Aligned.BS_to_tap.Phone == 1)];
% remove the gaps of not smartphone usage from the taps
[indexes] = find_gaps_in_taps(taps);
% only select the indexes that contain smartphone taps
eeg_dat = [];
eeg_times = [];
for gap=1:length(indexes)
    tmp_dat = EEG.data(:,indexes{gap});
    tmp_times = EEG.times(:,indexes{gap});
    eeg_dat = [eeg_dat tmp_dat];
    eeg_times = [eeg_times tmp_times];
end
% reassign the time of the EEG data note that urevent struct now is not usable anymore!
EEG.data = eeg_dat;
EEG.times = eeg_times;
EEG.pnts = length(EEG.data);
end