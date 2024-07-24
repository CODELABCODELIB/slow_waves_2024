function [load_data,res,all_files] = run_f_checkpoints(data_path, load_str,data_name,f, options)
%% load data checkpoints and concatonate 
%
% **Usage:**
%   -  [load_data,res,all_files] = run_f_checkpoints(data_path, load_str, data_name,f)
%   -  [load_data,res,all_files] = run_f_checkpoints(..., 'end_range', 10)
%   -  [load_data,res,all_files] = run_f_checkpoints(..., 'save_results', 0)
%
%  Input(s):
%   - data_path = path to checkpoint files with EEG data
%   - load_str = unique string in checkpoint name
%   - data_name = saved variable name e.g. 'A'
%   - f = function to run for all loaded data 
%
%  Optional Input(s):
%   - start_range (Default : 1) = Checkpoint to start with
%   - end_range (Default : length files) = Checkpoint to end with
%       note that the order of the checkpoints are given by the Dir() function
%       and does not necessarily mean the first checkpoint is also the
%       first subject (see dir output to know which files were loaded)
%   - save_results (Default : 1) = save function results
%   - save_path (Default : current folder) = path for saved datasets 
%       files are saved as save_path/checkpoint_<load_str>_<range>
%   - aggregate_res (Default : 1) = Aggregate the results of f from all the
%       checkpoints 
%   - parameter (Default : 1) = Argument that f can use
%
%  Output(s):
%   - load_data = EEG data from all checkpoints
%   - res = results of function for all loaded files of all participants
%   - all_files = list of checkpoint files in datapath
%
% Author: R.M.D. Kock, Leiden University

arguments
    data_path char;
    load_str char; 
    data_name char;
    f function_handle; 
    options.start_range = 1; % inclusive 
    options.end_range = [];
    options.save_results logical = 1;
    options.save_path = '.';
    options.aggregate_res logical = 1;
    options.parameter = 1; % for statistical analysis
end
% get all the file names on path with load_str in the name
folder_contents = dir(data_path);
files = {folder_contents.name};
all_files = files(cellfun(@(x) contains(x, load_str),files));
res = {};
% if no end range provided then run for all files
if isempty(options.end_range) 
    options.end_range = length(all_files);
end
%% load the EEG data in each checkpoint 
for i=options.start_range:options.end_range
    tmp = load(sprintf('%s/%s',data_path,all_files{i}));
    disp(sprintf('%s/%s',data_path,all_files{i}))
    load_data = {};
    % check if the checkpoint is not empty
    if ~(isempty(fieldnames(tmp))) &&  ~isempty(tmp.(data_name))
        % this is the 
        if strcmp(data_name, 'A')
            tmp = tmp.(data_name)(~cellfun(@isempty ,tmp.(data_name)));
            load_data = cat(1,load_data,tmp{:});
        else 
            load_data = tmp.(data_name);
        end
        % run the function on the loaded EEG structs from the checkpoint
        file_tmp = split(all_files{i},'.'); 
        [res_tmp] = f(load_data, 'save_path', options.save_path, 'save_results', options.save_results, 'file',file_tmp{1},'parameter', options.parameter);
        if options.aggregate_res
            res = cat(1,res,res_tmp);
        end
    end
end
if options.save_results
    save(sprintf('%s/EEG_res',options.save_path), 'res', '-v7.3')
end
end