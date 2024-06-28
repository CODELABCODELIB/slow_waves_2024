function [EEG,indexes,passive_RT_present,latencies] = find_movie_passive_event(EEG)
%% find where the movie passive events took place and select them
%
% **Usage:** [EEG] = find_movie_passive_event(EEG)
%
%  Input(s)
%   - EEG = EEG data struct
%
%  Output(s)
%   - EEG = EEG data struct with edited urevent only containing passive touches during movie
%
% Author: Arko Ghosh, Leiden University

%%
labels = {EEG.urevent.type}';
search_range = 30; % number of trials
if length(labels) <= search_range
    passive_RT_present = 0;
    indexes = [];
    return
end

latencies = [EEG.urevent.latency]';
labels_1 = strcmp(labels, 'S 33')'; % 1 --> RThumb
labels_2 = strcmp(labels, 'S 34')'; % 2 --> RLittle
labels_3 = strcmp(labels, 'S 36')'; % 4 --> LThumb
labels_4 = strcmp(labels, 'S 40')'; % 8 --> LLittle

% during movie, one of the '3' and '4' labels must be present in the
% subsequent search_range

for l = 1:(length(labels)-search_range)
    
    log_check = (logical(sum(labels_1(l:l+search_range))) && logical(sum(labels_2(l:l+search_range))) && logical(sum(labels_3(l:l+search_range))) && logical(sum(labels_4(l:l+search_range))));
    if sum(log_check)>=1
        Idx_movie(l:l+search_range) = true;
    else
        Idx_movie(l:l+search_range) = false;
    end
end
%% remove the non movie passive urevents
EEG.urevent(~Idx_movie) = [];
% remove any other RT data that might have been missed.
[~,rt_indexes,~] = getreactiotimepart(EEG);
EEG.urevent(rt_indexes.right) = [];
EEG.urevent(rt_indexes.left) = [];
%% remove the non movie passive events
EEG.event(~Idx_movie) = [];
EEG.event(rt_indexes.right) = [];
EEG.event(rt_indexes.left) = [];
%% recalculate indexes
labels = {EEG.urevent.type}';
latencies = [EEG.urevent.latency]';
labels_1 = strcmp(labels, 'S 33')'; % 1 --> RThumb
indexes.right = find(labels_1 == true);
labels_3 = strcmp(labels, 'S 36')'; % 4 --> LThumb
indexes.left = find(labels_3 == true);
passive_RT_present = any(labels_1) && any(labels_3);
end