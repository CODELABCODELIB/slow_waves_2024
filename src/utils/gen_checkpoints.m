function gen_checkpoints(unique_name,bandpass_lower,bandpass_upper, f, f2, options)
%% Calls functions to generate ERP/ERSP and saves results in checkpoint files
% Each checkpoint has 2 participant's data
%
% **Usage:**
%   - gen_checkpoints(unique_name,bandpass_upper, banpass_lower, aligned, erp_data)
%   - gen_checkpoints(... , 'count', 10)
%   - gen_checkpoints(... , 'epoch_window_ms', [-2000 2000])
%   - gen_checkpoints(... , 'epoch_window_baseline', [-2000 -1500])
%
%
% Input(s):
%   - unique_name = Description of data being saved, part of checkpoint file name
%   - bandpass_upper = Upper range bandpass filter
%   - bandpass_lower = Lower range bandpass filter
%   - f = function handle that function f2 will call
%   - f2 = function handle that this script will call
%
% Optional input parameter(s):
%   - aligned = Load aligned (1) or unaligned (0) data
%   - erp_data = load erp data (1) or ersp data (0)
%   - options.count **optional** = the number of participant to start the checkpoint
%   - options.epoch_window_ms **optional** = Epoch window in milliseconds
%   - options.epoch_window_baseline **optional** = Baseline window in milliseconds
%
% Output(s):
%   - Saved checkpoint files, file name format check_<unique_name>_<count_start>_<count_end>
%   Example: check_erspaligned10s45_10_to_12
%   Contains aligned ersp data of length 10 seconds bandpass filtered at upper bount 45 participant 10 to 12
%
% Requires:
%   - process_EEG
%   - call_f_all_p_parallel
%
% Author: R.M.D. Kock, Leiden University

arguments
    unique_name char;
    bandpass_lower double;
    bandpass_upper double;
    f function_handle;
    f2 function_handle;
    options.epoch_window_ms (1,2) double = [-2000 2000];
    options.epoch_window_baseline (1,2) double = [-2000 -1500];
    options.count = 1;
    options.type char = 'RT';
    options.timelocked = 1;
    options.pt logical = 1;
    options.num_files = 0;
    options.checkpoint_n = 2;
    options.processed_data_path = '/media/Storage/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG';
    options.save_path_upper = '/media/Storage/User_Specific_Data_Storage/ruchella/EEGsynclib_Mar_2022';
end
%% paths
save_folder = sprintf('erp_%s_%s_%d',unique_name,string(round(bandpass_lower,1)),bandpass_upper);
save_path = sprintf('%s/%s',options.save_path_upper,save_folder);
mkdir(save_path)
%% generate checkpoints
count = options.count;
for i=1:ceil((137-options.checkpoint_n)/options.checkpoint_n )
    [files_grouped,A,parfor_time] = f2(options.processed_data_path,f, 'start_idx', count, 'end_idx', count+options.checkpoint_n , 'bandpass_lower',bandpass_lower,'bandpass_upper',bandpass_upper, 'epoch_window_ms', options.epoch_window_ms, 'epoch_window_baseline', options.epoch_window_baseline, 'pt', options.pt, 'num_files', options.num_files);
    save(sprintf('%s/check_%s_%s_%d_%d_to_%d.mat',save_path,unique_name, string(round(bandpass_lower,1)),bandpass_upper,count, count+options.checkpoint_n ), 'A', '-v7.3')
    count = count+options.checkpoint_n +1;
end
end