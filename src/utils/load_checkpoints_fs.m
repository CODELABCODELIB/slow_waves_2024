function [load_data] = load_checkpoints(data_path, load_str,data_name, options)
%% load erp and or ersp checkpoints
%
% **Usage:**
%   -  [load_data] = load_checkpoints(path, load_str, data_name,)
%   -  [load_data] = load_checkpoints(..., 'split_trials', 0)
%   -  [load_data] = load_checkpoints(..., 'erp_data', 1)
%
%  Input(s):
%   - path = path to checkpoint files with erp and ersp data
%   - load_str = unique string in checkpoint name
%   - data_name = saved variable name e.g. 'A'
%   - options.split_trials **optional** logical = split trials (1) or not (0) (see split_trials.m)
%   - options.erp_data **optional** = load erp data (1) or ersp data (0)
%
%  Output(s):
%   - load_data = EEG data from all checkpoints
%
%
% Author: R.M.D. Kock, Leiden University

arguments
    data_path char;
    load_str char; % function_handle or cell array of function handles
    data_name char;
    options.split_trials logical = 1; % inclusive 
    options.erp_data logical = 1;
    options.time_range double = 10000;
    options.index = 4;
end
folder_contents = dir(data_path);
files = {folder_contents.name};
%%
all_files = files(cellfun(@(x) contains(x, load_str),files));
load_data = {};
for i=1:length(all_files)
    tmp = load(sprintf('%s/%s',data_path,all_files{i}));
    disp(sprintf('%s/%s',data_path,all_files{i}))
    if ~(isempty(fieldnames(tmp))) &&  ~isempty(tmp.(data_name))
        tmp = tmp.(data_name)(~cellfun(@isempty ,tmp.(data_name)));
        if options.split_trials && options.erp_data && ~isempty(tmp)
            [interp_data] = interp_RW(cat(1,tmp{:}), options.index,options.split_trials, 'time_range', options.time_range);
%             [participants] = split_trials(interp_data);
%             load_data = cat(1,load_data,participants);
            full = cat(1,interp_data);
%             full(:,4) = [];
            load_data = cat(1,load_data,full);
        elseif options.erp_data && ~isempty(tmp)
            [interp_data] = interp_RW(cat(1,tmp{:}),options.index,options.split_trials, 'time_range', options.time_range);
            full = cat(1,interp_data);
%             full(:,7) = [];
            load_data = cat(1,load_data,full);
        else
            load_data = cat(1,load_data,tmp{:});
        end
    end
end
end