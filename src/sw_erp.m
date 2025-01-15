function [res] = sw_to_behavior_all_pps(load_data,options)
%% Calculate SW to behavior features for all participants
%
% **Usage:**
%   -  sw_to_behavior_all_pps(load_data)
%   -  sw_to_behavior_all_pps(...,'save_results', 1, 'save_path','mydir', 'file', 'subject_2')
%   -  sw_to_behavior_all_pps(...,'parameter',2)
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
%   - save_results (Default : 1) = 1 save results, 0 otherwise
%   - save_path (Default : current directory) = string path to save results
%   - file (Default: empty) = Unique checkpoint file name to save results
%   - parameter (Default : 1) = number of minutes to select after a triad for post_rate and pre_rate
%
%  Output(s):
%   - res = struct array with the sw to behavior features containing the following fields:
%       taps = indexes of phone taps
%       refilter = slow waves for all channels
%       rate = the number of taps during a SW triad
%       post_rate = the number of taps x min minutes after a SW triad
%       pre_rate = the number of taps x min minutes before a SW triad
%       latency = the latency to next tap following a SW triad
%
% Author: R.M.D. Kock, Leiden University, 2024
arguments
    load_data;
    options.save_results logical = 1;
    options.save_path char = '.';
    options.file = '';
    options.parameter = 1;
end

res = struct();
count = 1;
for pp=1:size(load_data,1)
    [movie_indexes,phone_indexes,~,~,taps] = seperate_movie_phone(load_data(pp,:),'get_movie_idxs',1);
    if ~isempty(phone_indexes{:})
        % find the indexes for sws during behavior
        [~,~, behavior_sws] = tap_per_sw_triad(taps{1},load_data{pp,4},'rate');
        % find the indexes for sws during movie
        [~,~,movie_sws] = tap_per_sw_triad(movie_indexes{1}.movie_latencies,load_data{pp,4}, 'rate');

        % preset the relevant variables
        behavior_tmp_2 = zeros(64,2001);
        behavior_tmp_3 = zeros(64,2001);
        behavior_tmp_4 = zeros(64,2001);
        movie_tmp_2 = zeros(64,2001);
        movie_tmp_3 = zeros(64,2001);
        movie_tmp_4 = zeros(64,2001);
        for chan=1:64
            % select the sws in a window around the maximum negative peak (off state)
            sw_durations_4 = cellfun(@(x) x-1000:x+1000,load_data{1,4}.channels(chan).maxnegpk,'UniformOutput',false);
            % remove any sws that exceed that window
            sws_to_select_4 = cell2mat(cellfun(@(sw_event) all(sw_event<round(max(load_data{1,2}.times))),sw_durations_4,'UniformOutput',false));
            filtered_sws_4 = load_data{1,5}.filtered_sws_4(chan,:);
            % select the slow waves that happened during behavior
            behavior_sws_4 = filtered_sws_4([load_data{1,4}.channels(chan).maxnegpk{sws_to_select_4}] >= min([behavior_sws{chan,:}]));
            % remove any slow waves shorted than the window
            selected_4 = cellfun(@(x)length(x)==2001,behavior_sws_4);
            % calculate the ERP for behavior
            behavior_tmp_4(chan,:) = trimmean(cat(1,behavior_sws_4{selected_4}),20,1);
            % select the slow waves that happened during movie
            movie_sws_4 = filtered_sws_4([load_data{1,4}.channels(chan).maxnegpk{:}] <= max([movie_sws{chan,:}]));
            % remove any slow waves shorted than the window
            selected_4 = cellfun(@(x)length(x)==2001,movie_sws_4);
            % calculate the ERP for movie
            movie_tmp_4(chan,:) = trimmean(cat(1,movie_sws_4{selected_4}),20,1);

            % select the sws in a window around the negative zero crossing(start of sws)
            sw_durations_2 = cellfun(@(x,y) x:x+2000,load_data{1,4}.channels(chan).negzx,'UniformOutput',false);
            % remove any sws that exceed that window
            sws_to_select_2 = cell2mat(cellfun(@(sw_event) all(sw_event<round(max(load_data{1,2}.times))),sw_durations_2,'UniformOutput',false));
            filtered_sws_2 = load_data{1,5}.filtered_sws_2(chan,:);
            % select the slow waves that happened during behavior
            behavior_sws_2 = filtered_sws_2([load_data{1,4}.channels(chan).maxnegpk{sws_to_select_2}] >= min([behavior_sws{chan,:}]));
            % remove any slow waves shorted than the window
            selected_2 = cellfun(@(x)length(x)==2001,behavior_sws_2);
            % calculate the ERP for behavior
            behavior_tmp_2(chan,:) = trimmean(cat(1,behavior_sws_2{selected_2}),20,1);
            % select the slow waves that happened during movie
            movie_sws_2 = filtered_sws_2([load_data{1,4}.channels(chan).maxnegpk{:}] <= max([movie_sws{chan,:}]));
            % remove any slow waves shorted than the window
            selected_2 = cellfun(@(x)length(x)==2001,movie_sws_2);
            % calculate the ERP for movie
            movie_tmp_2(chan,:) = trimmean(cat(1,movie_sws_2{selected_2}),20,1);

            % select the sws in a window around the postive zero crossing
            sw_durations_3 = cellfun(@(x) x-1000:x+1000,load_data{1,4}.channels(chan).poszx,'UniformOutput',false);
            % remove any sws that exceed that window
            sws_to_select_3 = cell2mat(cellfun(@(sw_event) all(sw_event<round(max(load_data{1,2}.times))),sw_durations_3,'UniformOutput',false));
            filtered_sws_3 = load_data{1,5}.filtered_sws_3(chan,:);

            % select the slow waves that happened during behavior
            behavior_sws_3 = filtered_sws_3([load_data{1,4}.channels(chan).maxnegpk{sws_to_select_3}] >= min([behavior_sws{chan,:}]));
            % remove any slow waves shorted than the window
            selected_3 = cellfun(@(x)length(x)==2001,behavior_sws_3);
            % calculate the ERP for behavior
            behavior_tmp_3(chan,:) = trimmean(cat(1,behavior_sws_3{selected_3}),20,1);
            % select the slow waves that happened during movie
            movie_sws_3 = filtered_sws_3([load_data{1,4}.channels(chan).maxnegpk{:}] <= max([movie_sws{chan,:}]));
            % remove any slow waves shorted than the window
            selected_3 = cellfun(@(x)length(x)==2001,movie_sws_3);
            % calculate the ERP for movie
            movie_tmp_3(chan,:) = trimmean(cat(1,movie_sws_3{selected_3}),20,1);
        end
        res(pp).movie_sws = movie_sws;
        res(pp).behavior_sws = behavior_sws;
        res(pp).filtered_behavior_sws_2 = behavior_tmp_2;
        res(pp).filtered_behavior_sws_3 = behavior_tmp_3;
        res(pp).filtered_behavior_sws_4 = behavior_tmp_4;
        res(pp).filtered_movie_sws_2 = movie_tmp_2;
        res(pp).filtered_movie_sws_3 = movie_tmp_3;
        res(pp).filtered_movie_sws_4 = movie_tmp_4;
        if options.save_results
            save(sprintf('%s/%s_res_%d',options.save_path,options.file, pp),'res', '-v7.3')
        end
    end
end
end