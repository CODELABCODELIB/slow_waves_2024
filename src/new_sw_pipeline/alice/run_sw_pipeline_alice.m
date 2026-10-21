%% ALICE wrapper: run the refined SW pipeline on one dataset per Slurm array task
% Environment variables (set in sw_pipeline_array.slurm):
%   SW_INPUT_DIR         root folder with the participant folders (.set/.fdt)
%   SW_OUTPUT_DIR        folder with dataset_list.txt; receives Outputs/,
%                        ICA_Cache/ and batch_summaries/
%   SW_TASK_ID or        1-based line number in dataset_list.txt
%   SLURM_ARRAY_TASK_ID  (SW_TASK_ID is used by local_server/run_sw_local.sh)

input_directory = getenv('SW_INPUT_DIR');
output_root = getenv('SW_OUTPUT_DIR');
task_text = getenv('SW_TASK_ID');
if isempty(task_text)
    task_text = getenv('SLURM_ARRAY_TASK_ID');
end
task_id = str2double(task_text);

if isempty(input_directory) || exist(input_directory, 'dir') ~= 7
    error('alice:InputDirectory', 'SW_INPUT_DIR is not set or does not exist: "%s"', input_directory);
end
list_file = fullfile(output_root, 'dataset_list.txt');
if exist(list_file, 'file') ~= 2
    error('alice:DatasetList', 'Missing %s; submit with submit_sw_array.sh.', list_file);
end

dataset_list = strtrim(splitlines(fileread(list_file)));
dataset_list = dataset_list(~cellfun('isempty', dataset_list));
if isnan(task_id) || task_id < 1 || task_id > numel(dataset_list)
    error('alice:TaskID', 'Task ID "%s" is outside 1..%d.', task_text, numel(dataset_list));
end

% Paths in the list are relative to SW_INPUT_DIR, e.g. AT08/12_57_07_05_18.set.
relative_file = dataset_list{task_id};
dataset_file = fullfile(input_directory, relative_file);
dataset_id = regexprep(regexprep(relative_file, '\.set$', ''), '[^A-Za-z0-9_.-]', '_');
fprintf('Task %d/%d: %s (id %s)\n', task_id, numel(dataset_list), dataset_file, dataset_id);

summary_directory = fullfile(output_root, 'batch_summaries');
if exist(summary_directory, 'dir') ~= 7
    mkdir(summary_directory);
end

config_overrides = struct();
config_overrides.input_directory = input_directory;
config_overrides.dataset_files = {dataset_file};
config_overrides.dataset_ids = {dataset_id};
config_overrides.output_directory = fullfile(output_root, 'Outputs');
config_overrides.ica_cache_directory = fullfile(output_root, 'ICA_Cache');
config_overrides.refined_ica_mode = 'train';  % Always fit a fresh ICA.
config_overrides.continue_on_error = false;   % Failed dataset -> failed Slurm task.
config_overrides.save_cleaned_EEG = true;
config_overrides.batch_summary_file = fullfile(summary_directory, [dataset_id, '.csv']);

run_sw_pipeline;
