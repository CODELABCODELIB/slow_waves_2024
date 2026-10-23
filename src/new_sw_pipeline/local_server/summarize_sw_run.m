function report = summarize_sw_run(output_root)
%% Overview of a run_sw_local.sh / ALICE run: status and failure reason per task
%
% **Usage:**
%   - summarize_sw_run                       (uses $SW_OUTPUT_DIR or the run_sw_local default)
%   - summarize_sw_run('/path/to/sw_refined_ica_rerun')
%   - from the shell:
%       matlab -batch "addpath('<repo>/src/new_sw_pipeline/local_server'); summarize_sw_run"
%
%  Input(s):
%   - output_root = SW_OUTPUT_DIR of the run (contains dataset_list.txt,
%       Outputs/, batch_summaries/ and logs/)
%
%  Output(s):
%   - report = table with one row per task (also written to
%       <output_root>/run_report.csv). The grouped overview and the rerun
%       commands are printed and written to <output_root>/run_report.txt.
%
%  Status per task:
%   - ok      = wave_results.mat and cleaned_EEG.mat exist
%   - partial = only one of the two output files exists
%   - failed  = the pipeline caught an error (batch_summaries/<id>.csv)
%   - crashed = a log exists but no summary/outputs (MATLAB killed, OOM,
%               license or EEGLAB start-up error, ...)
%   - not_run = no log and no outputs
%
% Author: R.M.D. Kock, Leiden University, 2026
arguments
    output_root = '';
end
if isempty(output_root)
    output_root = getenv('SW_OUTPUT_DIR');
end
if isempty(output_root)
    output_root = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sw_refined_ica_rerun';
end
list_file = fullfile(output_root, 'dataset_list.txt');
if exist(list_file, 'file') ~= 2
    error('summarize:DatasetList', 'Missing %s', list_file);
end
dataset_list = strtrim(splitlines(fileread(list_file)));
dataset_list = dataset_list(~cellfun('isempty', dataset_list));
n_tasks = numel(dataset_list);

% one row per task
task = (1:n_tasks)';
[dataset_id, participant, status, reason_group, error_id, message, error_location, log_file] = ...
    deal(repmat({''}, n_tasks, 1));
elapsed_minutes = nan(n_tasks, 1);

for i = 1:n_tasks
    relative_file = dataset_list{i};
    % same ID rule as run_sw_pipeline_alice.m / run_sw_local.sh
    dataset_id{i} = regexprep(regexprep(relative_file, '\.set$', ''), '[^A-Za-z0-9_.-]', '_');
    folder = fileparts(relative_file);
    participant{i} = strtok(folder, '/');
    if isempty(participant{i})
        participant{i} = dataset_id{i};
    end
    out_dir = fullfile(output_root, 'Outputs', dataset_id{i}, 'refined');
    has_waves = exist(fullfile(out_dir, 'wave_results.mat'), 'file') == 2;
    has_clean = exist(fullfile(out_dir, 'cleaned_EEG.mat'), 'file') == 2;
    log_file{i} = fullfile(output_root, 'logs', sprintf('task_%d.log', i));
    has_log = exist(log_file{i}, 'file') == 2;
    if ~has_log
        log_file{i} = '';
    end

    % pipeline summary written by run_sw_pipeline.m
    csv_status = '';
    summary_file = fullfile(output_root, 'batch_summaries', [dataset_id{i}, '.csv']);
    if exist(summary_file, 'file') == 2
        try
            T = readtable(summary_file, 'TextType', 'char', 'Delimiter', ',');
            csv_status = to_text(T.status(end));
            elapsed_minutes(i) = T.elapsed_seconds(end) / 60;
            if ismember('error_identifier', T.Properties.VariableNames)
                error_id{i} = to_text(T.error_identifier(end));
            end
            if ismember('error_message', T.Properties.VariableNames)
                message{i} = to_text(T.error_message(end));
            end
        catch ME
            message{i} = sprintf('could not read %s: %s', summary_file, ME.message);
        end
    end
    error_file = fullfile(out_dir, 'processing_error.mat');
    if exist(error_file, 'file') == 2
        error_location{i} = first_error_frame(error_file);
    end

    if has_waves && has_clean
        status{i} = 'ok';
        error_id{i} = ''; message{i} = '';   % old error from an earlier attempt
    elseif has_waves || has_clean
        status{i} = 'partial';
        reason_group{i} = sprintf('partial outputs (wave_results=%d, cleaned_EEG=%d)', has_waves, has_clean);
    elseif strcmp(csv_status, 'failed')
        status{i} = 'failed';
        if isempty(error_id{i})
            reason_group{i} = normalise_message(message{i});
        else
            reason_group{i} = error_id{i};
        end
    elseif has_log
        status{i} = 'crashed';
        [reason_group{i}, message{i}] = reason_from_log(log_file{i});
    else
        status{i} = 'not_run';
        reason_group{i} = 'not run yet';
    end
end

report = table(task, dataset_id, participant, status, reason_group, error_id, ...
    message, error_location, elapsed_minutes, log_file);
writetable(report, fullfile(output_root, 'run_report.csv'));

%% Text overview
lines = {};
lines{end+1} = sprintf('SW run report: %s', output_root);
lines{end+1} = sprintf('%d tasks in %s', n_tasks, list_file);
lines{end+1} = '';
lines{end+1} = 'Status counts:';
for s = {'ok', 'partial', 'failed', 'crashed', 'not_run'}
    lines{end+1} = sprintf('  %-8s %4d', s{1}, sum(strcmp(status, s{1}))); %#ok<AGROW>
end

not_ok = find(~strcmp(status, 'ok'));
if ~isempty(not_ok)
    lines{end+1} = '';
    lines{end+1} = 'Reasons (grouped):';
    [groups, ~, group_idx] = unique(reason_group(not_ok));
    counts = accumarray(group_idx, 1);
    [~, order] = sort(counts, 'descend');
    for g = order'
        tasks_in_group = not_ok(group_idx == g);
        lines{end+1} = sprintf('  [%d] %s', counts(g), groups{g}); %#ok<AGROW>
        example = tasks_in_group(1);
        if ~isempty(message{example}) && ~strcmp(message{example}, groups{g})
            lines{end+1} = sprintf('      e.g. task %d: %s', example, one_line(message{example})); %#ok<AGROW>
        end
        if ~isempty(error_location{example})
            lines{end+1} = sprintf('      at: %s', error_location{example}); %#ok<AGROW>
        end
        lines{end+1} = sprintf('      tasks: %s', strjoin(arrayfun(@num2str, tasks_in_group', 'UniformOutput', false), ' ')); %#ok<AGROW>
        lines{end+1} = sprintf('      ids:   %s', strjoin(dataset_id(tasks_in_group)', ' ')); %#ok<AGROW>
        lines{end+1} = sprintf('      rerun: ./run_sw_local.sh %s', ...
            strjoin(arrayfun(@num2str, tasks_in_group', 'UniformOutput', false), ' ')); %#ok<AGROW>
    end

    lines{end+1} = '';
    lines{end+1} = 'Rerun everything that is not ok:';
    lines{end+1} = sprintf('  ./run_sw_local.sh %s', strjoin(arrayfun(@num2str, not_ok', 'UniformOutput', false), ' '));
    partial_tasks = find(strcmp(status, 'partial'));
    if ~isempty(partial_tasks)
        lines{end+1} = '  (partial tasks are rerun automatically because one output is missing)';
    end
end

% participants that would be missing from the plots
participants = unique(participant);
missing = participants(cellfun(@(p) ~any(strcmp(status(strcmp(participant, p)), 'ok')), participants));
lines{end+1} = '';
lines{end+1} = sprintf('Participants with at least one ok recording: %d / %d', ...
    numel(participants) - numel(missing), numel(participants));
if ~isempty(missing)
    lines{end+1} = sprintf('Participants with NO ok recording (%d): %s', numel(missing), strjoin(missing', ' '));
end
lines{end+1} = '';
lines{end+1} = sprintf('Per-task table: %s', fullfile(output_root, 'run_report.csv'));

text = strjoin(lines, newline);
fprintf('%s\n', text);
fid = fopen(fullfile(output_root, 'run_report.txt'), 'w');
fprintf(fid, '%s\n', text);
fclose(fid);
end

function location = first_error_frame(error_file)
% first "Error in ..." line of the saved getReport output
location = '';
try
    tmp = load(error_file, 'error_report');
    report_lines = splitlines(tmp.error_report);
    hit = find(startsWith(strtrim(report_lines), 'Error in'), 1);
    if ~isempty(hit)
        location = strtrim(report_lines{hit});
    end
catch
end
end

function [group, msg] = reason_from_log(log_file)
% classify a run that died without writing a batch summary
log_lines = strtrim(splitlines(fileread(log_file)));
log_lines = log_lines(~cellfun('isempty', log_lines));
if isempty(log_lines)
    group = 'crashed: empty log (killed before MATLAB started?)';
    msg = '';
    return
end
msg = strjoin(log_lines(max(1, end-2):end), ' | ');
full_log = strjoin(log_lines, newline);
patterns = {
    'Killed',                        'crashed: process killed (likely out of memory)'
    'Out of memory',                 'crashed: MATLAB out of memory'
    'Requested .* array exceeds',    'crashed: MATLAB out of memory'
    'License',                       'crashed: MATLAB license error'
    'Octave',                        'crashed: EEGLAB thinks MATLAB is Octave (see README)'
    'Undefined function',            'crashed: undefined function (path/EEGLAB problem)'
    'alice:',                        'crashed: wrapper error (input dir / dataset list / task id)'
    };
group = '';
for p = 1:size(patterns, 1)
    if ~isempty(regexp(full_log, patterns{p, 1}, 'once'))
        group = patterns{p, 2};
        break
    end
end
if isempty(group)
    error_line = find(startsWith(log_lines, 'Error'), 1, 'last');
    if ~isempty(error_line)
        group = ['crashed: ', normalise_message(log_lines{error_line})];
    else
        group = 'crashed: unknown (log ends without error, still running or killed?)';
    end
end
end

function msg = normalise_message(msg)
% make messages that differ only in numbers/paths fall into one group
msg = one_line(msg);
msg = regexprep(msg, '(/[^\s''"]+)+', '<path>');
msg = regexprep(msg, '\d+(\.\d+)?', 'N');
if strlength(msg) > 120
    msg = [msg(1:117), '...'];
end
if isempty(msg)
    msg = 'failed without message';
end
end

function s = to_text(value)
% readtable gives NaN for empty text columns
if iscell(value)
    value = value{1};
end
if isnumeric(value) || ismissing(string(value))
    s = '';
else
    s = char(string(value));
end
end

function s = one_line(s)
s = strtrim(regexprep(char(s), '\s+', ' '));
end
