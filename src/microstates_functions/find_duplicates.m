function [duplicates] = find_duplicates(dt_dt)
%% find multiple triads in each bin
%
% **Usage:**
%   - find_duplicates(dt_dt)
%
% Input(s):
%    dt_dt = array of triads with ITI of index K and ITI of index k+1 
%    microstates = all the microstates fitted on the EEG data
%
% Output(s):
%   - duplicates: logical array indicating whether a triad is a duplicate 
%
% Author: R.M.D. Kock, Leiden University
%
%% 
% initiate an empty array of length equal to number of triads
duplicates = zeros(size(dt_dt,1));
for sel_tap=1:size(dt_dt,1)
    duplicates(sel_tap,:) = dt_dt(:,3) == dt_dt(sel_tap,3) & dt_dt(:,4) == dt_dt(sel_tap,4);
end
duplicates = logical(duplicates);
end