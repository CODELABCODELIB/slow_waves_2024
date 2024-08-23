function [pooled,duplicates_sel,duplicates] = pool_duplicates(dt_dt,microstates,options)
%% find multiple triads in each bin
%
% **Usage:**
%   - pool_duplicates(dt_dt,pool_duplicates)
%
% Input(s):
%    dt_dt = array of triads with ITI of index K and ITI of index k+1 
%    microstates = all the microstates fitted on the EEG data
%
% Output(s):
%   - pooled: pooled data in each bin
%
% Author: R.M.D. Kock, Leiden University
%
%%
arguments
    dt_dt;
    microstates;
    options.pool_method = 'mean';
end
% find all duplicates that need to be pooled together somehow
[duplicates] = find_duplicates(dt_dt);
%% pool them together
pooled = zeros(size(dt_dt,1),1);
duplicates_sel = cell(size(dt_dt,1),1);
for sel_tap=1:size(dt_dt,1)
     % select the active state at the time of the tap
     states = microstates(duplicates(sel_tap,:));
     duplicates_sel{sel_tap} = states;
     if strcmp(options.pool_method, 'mode')
         % select the mode in the bins
         pooled(sel_tap,1) = mode(states);
     elseif strcmp(options.pool_method, 'mean')
         pooled(sel_tap,1) = mean(states, 'omitnan');
     elseif strcmp(options.pool_method, 'sum')
         pooled(sel_tap,1) = sum(states);
     elseif strcmp(options.pool_method, 'median')
         pooled(sel_tap,1) = median(states, 'omitnan');
     end
end