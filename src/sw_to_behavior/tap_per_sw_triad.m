function [selected_waves,triad_lengths] = tap_per_sw_triad(taps,refilter,type,options)
%% Select the slow wave per electrode and triad
%
% **Usage:**
%   -  tap_per_sw_triad(taps,refilter,type)
%   -  tap_per_sw_triad(...,'mins',2)
%
%  Input(s):
%   - taps = tap indexes
%   - refilter = Slow waves
%   - type = 
%       'rate' select the number of taps during a SW triad 
%       'post_rate' select the number of taps options.min minutes after a SW triad 
%       'pre_rate' select the number of taps options.min minutes before a SW triad 
%       'latency' select the latency to next tap following a SW triad
%
%  Optional Input(s):
%   - mins (Default : 1) = number of minutes to select after a triad for
%      post_rate and pre_rate
%
%  Output(s):
%   - selected_waves = cell channels x triads, inside each cell an array of
%       logical values 1 if sw was present and 0 otherwise
%   - triad_lengths = total duration of the traids
%
% Author: R.M.D. Kock, Leiden University, 2024
arguments
    taps;
    refilter;
    type;
    options.mins = 1;
end
% get maximum amount of SW across all channels
max_all = max(cell2mat(cellfun(@(x) length(x),{refilter.channels.negzx},'UniformOutput',false)));
% initiate cells
selected_waves = cell(64,length(max_all)-2);
triad_lengths = cell(64,length(max_all)-2); 
for chan=1:length(refilter.channels)
    slow_waves = [refilter.channels(chan).maxnegpk{:}];
    for triad_idx = 1:length(slow_waves)-2
        triad = slow_waves(triad_idx:triad_idx+2);
        % calculate triad length
        triad_lengths{chan,triad_idx} = triad(end)-triad(1);
        % SW rate -> number of taps during a triad
        if strcmp(type, 'rate')
            tmp = taps(taps >= triad(1) & taps <= triad(end));
            selected_waves{chan,triad_idx} = length(tmp);
        % SW post rate -> number of taps x min following a triad
        elseif strcmp(type, 'post_rate')
            tmp = taps(taps >= triad(end) & taps <= triad(end)+(options.mins*60*1000));
            selected_waves{chan,triad_idx} = length(tmp);
        % SW pre rate -> number of taps x min before a triad
        elseif strcmp(type, 'pre_rate')
            tmp = taps(taps >= triad(1)-(options.mins*60*1000) & taps <= triad(1));
            selected_waves{chan,triad_idx} = length(tmp);
        % SW latency -> distance to the next tap following a SW triad
        elseif strcmp(type, 'latency')
            tmp = taps(taps > triad(end));
            if ~isempty(tmp)
                selected_waves{chan,triad_idx} = tmp(1)-triad(end);
            else
                selected_waves{chan,triad_idx} = NaN;
            end
        end
    end
end