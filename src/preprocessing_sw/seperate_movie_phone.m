function [movie_indexes,phone_indexes,sw_movie,sw_phone,taps] = seperate_movie_phone(load_data, options)
%% seperate movie and phone data for each participant
%
% **Usage:**
%   - [movie_indexes,phone_indexes,sw_movie,sw_behavior] = seperate_movie_phone(load_data)
%   - seperate_movie_phone(...,'sel_sw','negzx')
%
%  Input(s):
%   - load_data = pre-processed struct with sw results from @sw_detection
%   - data_name = saved variable name e.g. 'A'
%   - f = function handle to run with loaded data
%
%  Optional Input(s):
%   - sel_sw (Default : '') = select sw indexes occuring during movie or phone use
%       sw signal. Options include: 'negzx','poszx','maxpospkamp','maxnegpk','mxdnslp','mxupslp'
%       If empty no selection is made.
%   - start_range (Default : 1) = Checkpoint to start with
%   - end_range (Default : length files) = Checkpoint to end with.
%   - get_movie_idxs (Default : 1) = 1 yes select movie indexes, 0 otherwise
%   - get_phone_idxs (Default : 1) = 1 yes select phone indexes, 0 otherwise
%
%  Output(s):
%   - movie_indexes = movie indexes
%   - phone_indexes = phone indexes (If empty there was no aligned phone data)
%   - sw_movie = sw indexes during movie watching (the selected index is
%       based on the 'sel_sw' For example if 'sel_sw' = 'negzx' then the
%       negzx indexes are selected.
%   - sw_phone = sw indexes during phone use
%
%   Note to run the function for only one file either only give it the
%   load_data for one file or specify start_range and end_range to be
%   equal. For instance if load_data has 3 files and you want the results
%   for file 2 then do load_data(2,:) or set 'start_range' = 2, 'end_range' = 2
%
% Author: R.M.D. Kock, Leiden University, 2024

arguments
    load_data;
    options.start_range = 1;
    options.end_range = [];
    options.sel_sw char = '';
    options.get_movie_idxs logical = 1;
    options.get_phone_idxs logical = 1;
end
% if end_range is not given run the function for all the participants in
% load_data
if isempty(options.end_range)
    options.end_range = size(load_data,1);
end
% initialize  variables
n_checkpoints = options.end_range-options.start_range;
movie_indexes=cell(n_checkpoints,1); phone_indexes=cell(n_checkpoints,1);
sw_movie=cell(n_checkpoints,1); sw_phone=cell(n_checkpoints,1);
taps = cell(n_checkpoints,1);
%% run function for all participants in loaded file
for pp=options.start_range:options.end_range
    EEG = load_data{pp,2};
    if ~isempty(options.sel_sw)
        sw = cell2mat(load_data{pp, 4}.channels(1).(options.sel_sw));
    end
    %% get the movie indexes
    if options.get_movie_idxs
        EEG.data = zeros(64,length(EEG.times));
        % upsampled to orginal freq for the right urevent and event indexes
        [EEG] = pop_resample(EEG, 1000);
        % find the movie indexes in upsampled data
        [~,movie_indexes{pp}] = find_movie_passive_event(EEG);

        % select the SW during movie watching (start index of the wave)
        if ~isempty(options.sel_sw)
            sw_movie{pp} = sw(sw > movie_indexes{pp}.movie_latencies(1) & sw < movie_indexes{pp}.movie_latencies(end));
        end
    end
    %% get the EEG indexes only if taps were aligned
    if isfield(EEG.Aligned, 'BS_to_tap') && options.get_phone_idxs
        % calculate number of taps
        num_taps = size(find(EEG.Aligned.BS_to_tap.Phone == 1),2);
        % add taps to the struct
        [EEG] = add_events(EEG,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
        latencies = [EEG.event.latency];
        % get tap indexes
        taps{pp} = latencies(strcmp({EEG.event.type}, 'pt'));
        % find phone indexes without the gaps
        [phone_indexes{pp}] = find_gaps_in_taps(taps{pp});
        tmp = {};
        % there may be multiple indexes if there was a gap
        % loop over all of them and select the sws
        if ~isempty(options.sel_sw)
            for gap=1:length(phone_indexes{pp})
                sws_p_gap = sw(sw > phone_indexes{pp}{gap}(1) & sw < phone_indexes{pp}{gap}(end));
                tmp = cat(1,tmp,sws_p_gap);
            end
            sw_phone{pp} = tmp;
        end
        % check if the phone and movie indexes are not overlapping
        % intersect(movie_indexes.movie_latencies(end),indexes{1})
    end
end