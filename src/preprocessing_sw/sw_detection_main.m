function [res] = sw_detection_main(load_data,options)
%% Calculate SW to behavior features for all participants
%
% **Usage:**
%   -  sw_detection_main(load_data)
%   -  sw_detection_main(...,'save_results', 1, 'save_path','mydir', 'file', 'subject_2')
%   -  sw_detection_main(...,'parameter',2)
%
%  Input(s):
%   - taps = tap indexes
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
    options.remove_EEG = 1;
end

res = struct();
[load_data] = pre_process_EEG_struct(load_data);
for pp=1:size(load_data,1)
    EEG = load_data{pp,2};
    participant = load_data{pp,1};
    res = sw_detection(EEG, participant, options);
    if options.save_results
        save(sprintf('%s/%s_res_%d',options.save_path,options.file, pp),'res', '-v7.3')
    end
end