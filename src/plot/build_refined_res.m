function [res, EEG, participant_ids] = build_refined_res(output_root, options)
%% Build the SW-to-behaviour res struct from the refined SW pipeline outputs
%
% **Usage:**
%   - [res, EEG] = build_refined_res(output_root)
%   - build_refined_res(..., 'plot_data_path', mydir, 'max_datasets', 2, 'select', 0)
%
%  Input(s):
%   - output_root = SW_OUTPUT_DIR of the run (dataset_list.txt, Outputs/<id>/refined/wave_results.mat)
%
%  Optional Input(s):
%   - plot_data_path (Default : <output_root>/plot_data) = cache folder (res_refined.mat,
%       durations.txt, timing_check.csv, selected_recordings.txt)
%   - max_datasets (Default : Inf) = only use the first N recordings (test run, not cached)
%   - select (Default : 1) = 1 keep one recording per participant (participant_selection), 0 keep all
%
%  Output(s):
%   - res = struct array as made by sw_to_behavior_all_pps, res.pp = dataset id
%   - EEG = struct with chanlocs (62 analysed channels) and Orignalchanlocs (all 64,
%       for the sort_electrodes grid order)
%   - participant_ids = participant folder per res entry (e.g. 'AT08')
%
% res (before participant selection) is cached in <plot_data_path>/res_refined.mat
% when every wave_results.mat could be read; delete it to rebuild.
%
% Author: R.M.D. Kock, Leiden University, 2026
arguments
    output_root char;
    options.plot_data_path = '';
    options.max_datasets = Inf;
    options.select logical = 1;
end
plot_data_path = options.plot_data_path;
if isempty(plot_data_path)
    plot_data_path = sprintf('%s/plot_data',output_root);
end
if ~exist(plot_data_path, 'dir'); mkdir(plot_data_path); end
%% participant folder per dataset id (same ID rule as run_sw_pipeline_alice.m)
dataset_list = strtrim(splitlines(fileread(sprintf('%s/dataset_list.txt',output_root))));
dataset_list = dataset_list(~cellfun('isempty', dataset_list));
list_ids = regexprep(regexprep(dataset_list, '\.set$', ''), '[^A-Za-z0-9_.-]', '_');
list_participants = cellfun(@(x) strtok(x, '/'), dataset_list, 'UniformOutput', false);
%% build res from the new outputs
res_file = sprintf('%s/res_refined.mat',plot_data_path);
if exist(res_file, 'file') && isinf(options.max_datasets)
    fprintf('Loading cached %s\n', res_file)
    load(res_file, 'res')
else
    result_files = dir(sprintf('%s/Outputs/*/refined/wave_results.mat',output_root));
    [~, order] = sort(fullfile({result_files.folder}, {result_files.name}));
    result_files = result_files(order);
    result_files = result_files(1:min(options.max_datasets, numel(result_files)));
    durations_file = sprintf('%s/durations.txt',plot_data_path);
    if exist(durations_file, 'file'); delete(durations_file); end
    res = {};
    unreadable = {};
    timing = cell(numel(result_files), 3);
    for i=1:numel(result_files)
        wave_file = fullfile(result_files(i).folder, result_files(i).name);
        dataset_id = regexp(wave_file, '[\\/]Outputs[\\/]([^\\/]+)[\\/]refined[\\/]', 'tokens', 'once');
        dataset_id = dataset_id{1};
        fprintf('%d/%d %s\n', i, numel(result_files), dataset_id)
        try
            tmp = load(wave_file, 'top10_filtered_results', 'recording_info');
        catch ME
            % e.g. task killed while saving or still running; see summarize_sw_run
            fprintf(2, '  skipped %s: cannot read wave_results.mat (%s)\n', dataset_id, ME.message);
            unreadable{end+1} = dataset_id; %#ok<AGROW>
            continue
        end
        info = tmp.recording_info;
        % SW positions must be on the same 1000 Hz clock as the events and taps
        max_shift = timing_shift(tmp.top10_filtered_results, info);
        timing(i,:) = {dataset_id, info.srate, max_shift};
        if info.srate ~= 1000
            fprintf(2, '  skipped %s: native srate %g Hz, the analyses assume 1000 Hz (1 sample = 1 ms)\n', ...
                dataset_id, info.srate);
            continue
        end
        if max_shift > 10
            fprintf(2, '  WARNING %s: maxnegpk differs up to %.0f samples from maxnegpk_seconds; data were removed?\n', ...
                dataset_id, max_shift);
        end
        load_data = {dataset_id, refined_eeg_stub(info), [], tmp.top10_filtered_results};
        try
            res_pp = sw_to_behavior_all_pps(load_data, 'save_results', 0, 'save_path', plot_data_path, 'file', dataset_id);
            if isfield(res_pp, 'taps')
                res{end+1} = res_pp; %#ok<AGROW>
            else
                fprintf('  skipped %s: no aligned phone taps\n', dataset_id)
            end
        catch ME
            fprintf(2, '  skipped %s: %s\n', dataset_id, ME.message);
        end
    end
    timing = timing(~cellfun('isempty', timing(:,1)),:);
    writetable(cell2table(timing, 'VariableNames', {'dataset_id','srate','max_maxnegpk_shift_samples'}), ...
        sprintf('%s/timing_check.csv',plot_data_path));
    res = cat(2,res{:});
    if ~isempty(unreadable)
        fprintf(2, '%d unreadable wave_results.mat (rerun with FORCE=1 ./run_sw_local.sh <task>): %s\n', ...
            numel(unreadable), strjoin(unreadable, ' '));
    end
    % only cache complete runs, so rerun datasets are picked up next time
    if isinf(options.max_datasets) && isempty(unreadable) && ~isempty(res)
        save(res_file, 'res', '-v7.3')
    end
end
if isempty(res)
    error('build_refined_res:NoData', ['No dataset could be converted to res; ' ...
        'see the "skipped <id>: ..." lines above for the reason per dataset.']);
end
%% channel locations
% chanlocs: the 62 analysed channels (E63/E64 removed). Orignalchanlocs: all 64,
% so sort_electrodes gives the same grid order as before (E63/E64 tiles stay empty)
tmp = load(sprintf('%s/Outputs/%s/refined/wave_results.mat',output_root,res(1).pp), 'recording_info', 'chanlocs');
EEG = struct('chanlocs', tmp.chanlocs);
if isfield(tmp.recording_info, 'Orignalchanlocs')
    EEG.Orignalchanlocs = tmp.recording_info.Orignalchanlocs;
elseif isfield(tmp.recording_info, 'Originalchanlocs')
    EEG.Orignalchanlocs = tmp.recording_info.Originalchanlocs;
else
    EEG.Orignalchanlocs = tmp.chanlocs;
end
%% one recording per participant (same rule as the old analysis)
[~, list_idx] = ismember({res.pp}, list_ids);
participant_ids = list_participants(list_idx)';
if options.select
    res = participant_selection(res, 'durations_file', sprintf('%s/durations.txt',plot_data_path), ...
        'participant_ids', participant_ids);
    [~, list_idx] = ismember({res.pp}, list_ids);
    participant_ids = list_participants(list_idx)';
    fprintf('%d recordings selected: %s\n', numel(res), strjoin({res.pp}, ' '))
    writecell({res.pp}', sprintf('%s/selected_recordings.txt',plot_data_path))
end
end

function max_shift = timing_shift(top10_filtered_results, recording_info)
% largest difference (native samples) between maxnegpk and the exact maxnegpk_seconds
max_shift = 0;
if ~isfield(top10_filtered_results.channels, 'maxnegpk_seconds')
    max_shift = NaN;
    return
end
for ch = 1:numel(top10_filtered_results.channels)
    channel = top10_filtered_results.channels(ch);
    if isempty(channel.maxnegpk); continue; end
    exact = (double([channel.maxnegpk_seconds{:}]) - recording_info.xmin)*recording_info.srate + 1;
    max_shift = max([max_shift, abs(double([channel.maxnegpk{:}]) - exact)]);
end
end
