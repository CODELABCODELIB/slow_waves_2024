function [indexes] = find_gaps_in_taps(taps,gap_length)
%% Indexes of smartphone tap data, remove any sequences/gaps with no touches
%
% **Usage:**
%   - find_gaps_in_taps(taps)
%   - find_gaps_in_taps(..., break_time, 100000)
%
% Input(s):
%    taps = latencies a smartphone touchscreen interaction/tap took place (in ms)
%
% Optional input parameter(s):
%    gap_length (default = 600000/ 10 minutes) - length of the gap with no touches(in ms)
%
% Output(s):
%    indexes cell = latencies where tap sequences take place, if there are
%                   multiple gaps then the cell is of size (1 x number of gaps)
%
% Ruchella Kock, Leiden University, 22/08/2023 
%
arguments 
    taps;
    gap_length = 600000;
end
%% 
indexes = {};
% intertap interval (ITI) identifies the distance to the next touch 
ITI = diff(taps);
% if this distance is larger than the gap_length then it is a large
% sequence of inactivity
gaps = find(ITI > gap_length);
% if there are sequences of inactivity then those are not selected 
count = 1;
if gaps
    for gap=1:length(gaps)
        indexes{gap} = taps(count):taps(gaps(gap));
        count = gaps(gap)+1;
    end
    indexes{gap+1} = taps(count):taps(end);
% otherwise the whole sequences since the first to last touch is selected
else
    indexes{1} = taps(count):taps(end);
end
end

