function [selected_waves,triad_lengths] = sw_per_tap_triad(taps,refilter)
%% Select the slow wave per electrode and triad  
%
% **Usage:**
%   -  sw_per_triad(taps,refilter)
%
%  Input(s):
%   - taps = tap indexes
%   - refilter = Slow waves   
%
%  Optional Input(s):
%
%  Output(s):
%   - selected_waves = cell channels x triads, inside each cell an array of
%       logical values 1 if sw was present and 0 otherwise
%   - triad_lengths = total duration of the traids
%
% Author: R.M.D. Kock, Leiden University, 2024

selected_waves = cell(64,length(taps)-2);
triad_lengths = nan(length(taps)-2,1);
for chan=1:length(refilter.channels)
    slow_waves = [refilter.channels(chan).maxnegpk{:}];
    for triad_idx = 1:length(taps)-2
        triad = taps(triad_idx:triad_idx+2);
        tmp = slow_waves>triad(1) & slow_waves<triad(end);
        selected_waves{chan,triad_idx} = tmp;
        triad_lengths(triad_idx,1) = triad(end)-triad(1);
    end
end