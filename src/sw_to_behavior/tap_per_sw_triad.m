function [selected_waves,triad_lengths,behavior_sws_cell,behavior_sws_indexes] = tap_per_sw_triad(taps,refilter,type,options)
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
max_all = max(cell2mat(cellfun(@(sw) length(sw([sw{:}]>=taps(1) & [sw{:}]<=taps(end))),{refilter.channels.maxnegpk},'UniformOutput',false)));

% initiate cells
selected_waves = cell(64,max_all-2);
triad_lengths = cell(64,max_all-2);
behavior_sws_cell = cell(64,max_all-2);
for chan=1:length(refilter.channels)
    slow_waves_start = [refilter.channels(chan).maxnegpk{:}];
    behavior_sws_indexes = slow_waves_start>=taps(1) & slow_waves_start<=taps(end);
    behavior_sws = slow_waves_start(behavior_sws_indexes);
    behavior_sws_cell(chan,1:length(behavior_sws)) = num2cell(behavior_sws);
    for triad_idx = 1:length(behavior_sws)-2
        triad = behavior_sws(triad_idx:triad_idx+2);
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
            slow_waves_end = [refilter.channels(chan).wvend{:}];
            behavior_sws_end = slow_waves_end(slow_waves_start>=taps(1) & slow_waves_start<=taps(end));
            triad = [behavior_sws(triad_idx:triad_idx+1),behavior_sws_end(triad_idx+2)];
            tmp = taps(taps > triad(end));
            if ~isempty(tmp)
                selected_waves{chan,triad_idx} = tmp(1)-triad(end);
            else
                selected_waves{chan,triad_idx} = NaN;
            end
        elseif strcmp(type, 'amplitude')
            neg_amplitudes = [refilter.channels(chan).maxnegpkamp{:}];
            neg_amplitudes = neg_amplitudes(slow_waves_start>=taps(1) & slow_waves_start<=taps(end));
            pos_amplitudes = [refilter.channels(chan).maxpospkamp{:}];
            pos_amplitudes(slow_waves_start>=taps(1) & slow_waves_start<=taps(end));

            triad_neg = neg_amplitudes(triad_idx:triad_idx+2);
            triad_pos = pos_amplitudes(triad_idx:triad_idx+2);
            triad_amp = abs(triad_pos-triad_neg);
            selected_waves{chan,triad_idx} = triad_amp;
        end
    end
end