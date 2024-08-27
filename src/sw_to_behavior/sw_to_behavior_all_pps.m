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
    % get tap indexes
    [~,phone_indexes,~,~,taps] = seperate_movie_phone(load_data(pp,:),'get_movie_idxs',0);
    if ~isempty(phone_indexes)
        res(count).taps = taps{1};
        res(count).refilter = load_data{count,4};
    
        [res(count).rate,res(count).triad_lengths] = tap_per_sw_triad(res(count).taps,res(count).refilter,'rate');

        res(count).post_rate= tap_per_sw_triad(res(count).taps,res(count).refilter,'post_rate', 'mins',options.parameter);

        res(count).pre_rate = tap_per_sw_triad(res(count).taps,res(count).refilter,'pre_rate', 'mins',options.parameter);

        res(count).latency = tap_per_sw_triad(res(count).taps,res(count).refilter,'latency');

        count = count +1;
        if options.save_results
            save(sprintf('%s/%s_res_%d',options.save_path,options.file, pp),'res')
        end
    end
end
end