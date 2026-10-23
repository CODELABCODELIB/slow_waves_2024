%% Paper SW-to-behaviour figures from the refined-ICA rerun
% Builds res (sw_to_behavior_all_pps) from Outputs/<id>/refined/wave_results.mat,
% selects one recording per participant (participant_selection) and runs
% prepare_sw_data_for_plotting (population plots) and sw_to_behavior_plots.
%
% Run on the server:
%   nohup matlab -batch "run('<repo>/src/plot/run_paper_sw_plots.m')" > plots.out 2>&1 &
%
% res is cached in <output_root>/plot_data/res_refined.mat; delete it to rebuild.
% output_root and max_datasets can be set before running, e.g. a test run:
%   max_datasets = 2; run('<repo>/src/plot/run_paper_sw_plots.m')
%% settings
if ~exist('output_root','var'); output_root = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sw_refined_ica_rerun'; end
figures_save_path = sprintf('%s/figures',output_root);
plot_data_path = sprintf('%s/plot_data',output_root);
data_save_path = output_root; % prepare_sw_data_for_plotting saves in <data_save_path>/plot_data
save_string = ''; % no extra subfolder in sw_to_behavior_plots
if ~exist('max_datasets','var'); max_datasets = Inf; end % e.g. 2 for a test run (test runs are not cached)
%% add folders to paths (this repo, EEGLAB and taps2JID)
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))))
addpath(genpath('/home/ruchella/imports'))
addpath(genpath('/home/ruchella/TapDataAnalysis'))
%% create output folders
for folder = {figures_save_path, plot_data_path, sprintf('%s/pop',figures_save_path), ...
        sprintf('%s/sw_to_behavior',figures_save_path), sprintf('%s/rates',figures_save_path)}
    if ~exist(folder{1}, 'dir'); mkdir(folder{1}); end
end
set(0, 'DefaultFigureVisible', 'off');
%% participant folder per dataset id (same ID rule as run_sw_pipeline_alice.m)
dataset_list = strtrim(splitlines(fileread(sprintf('%s/dataset_list.txt',output_root))));
dataset_list = dataset_list(~cellfun('isempty', dataset_list));
list_ids = regexprep(regexprep(dataset_list, '\.set$', ''), '[^A-Za-z0-9_.-]', '_');
list_participants = cellfun(@(x) strtok(x, '/'), dataset_list, 'UniformOutput', false);
%% build res from the new outputs
res_file = sprintf('%s/res_refined.mat',plot_data_path);
if exist(res_file, 'file') && isinf(max_datasets)
    load(res_file, 'res', 'EEG')
else
    result_files = dir(sprintf('%s/Outputs/*/refined/wave_results.mat',output_root));
    [~, order] = sort(fullfile({result_files.folder}, {result_files.name}));
    result_files = result_files(order);
    result_files = result_files(1:min(max_datasets, numel(result_files)));
    durations_file = sprintf('%s/durations.txt',plot_data_path);
    if exist(durations_file, 'file'); delete(durations_file); end
    res = {};
    EEG = [];
    unreadable = {};
    for i=1:numel(result_files)
        wave_file = fullfile(result_files(i).folder, result_files(i).name);
        dataset_id = regexp(wave_file, '[\\/]Outputs[\\/]([^\\/]+)[\\/]refined[\\/]', 'tokens', 'once');
        dataset_id = dataset_id{1};
        fprintf('%d/%d %s\n', i, numel(result_files), dataset_id)
        try
            tmp = load(wave_file, 'top10_filtered_results', 'recording_info', 'chanlocs');
        catch ME
            % e.g. task killed while saving or still running; see summarize_sw_run
            fprintf(2, '  skipped %s: cannot read wave_results.mat (%s)\n', dataset_id, ME.message);
            unreadable{end+1} = dataset_id; %#ok<SAGROW>
            continue
        end
        info = tmp.recording_info;
        % EEG struct without data, as in the old checkpoints (get_eeg_structs)
        EEG_stub = eeg_emptyset;
        EEG_stub.srate = info.srate; EEG_stub.pnts = info.pnts; EEG_stub.nbchan = 64;
        EEG_stub.trials = 1; EEG_stub.xmin = info.xmin;
        EEG_stub.xmax = info.xmin + (info.pnts-1)/info.srate;
        EEG_stub.times = (info.xmin + (0:info.pnts-1)/info.srate)*1000;
        EEG_stub.event = info.event; EEG_stub.urevent = info.urevent;
        EEG_stub.chanlocs = [];
        if isfield(info, 'Aligned'); EEG_stub.Aligned = info.Aligned; else; EEG_stub.Aligned = struct(); end
        load_data = {dataset_id, EEG_stub, [], tmp.top10_filtered_results};
        try
            res_pp = sw_to_behavior_all_pps(load_data, 'save_results', 0, 'save_path', plot_data_path, 'file', dataset_id);
            if isfield(res_pp, 'taps')
                res{end+1} = res_pp; %#ok<SAGROW>
            else
                fprintf('  skipped %s: no aligned phone taps\n', dataset_id)
            end
        catch ME
            fprintf(2, '  skipped %s: %s\n', dataset_id, ME.message);
        end
        % channel locations for the population plots (62 channels, E63/E64 removed)
        if isempty(EEG)
            EEG.chanlocs = tmp.chanlocs;
            if isfield(info, 'Orignalchanlocs')
                EEG.Orignalchanlocs = info.Orignalchanlocs(1:numel(tmp.chanlocs));
            elseif isfield(info, 'Originalchanlocs')
                EEG.Orignalchanlocs = info.Originalchanlocs(1:numel(tmp.chanlocs));
            else
                EEG.Orignalchanlocs = tmp.chanlocs;
            end
        end
    end
    res = cat(2,res{:});
    if ~isempty(unreadable)
        fprintf(2, '%d unreadable wave_results.mat (rerun with FORCE=1 ./run_sw_local.sh <task>): %s\n', ...
            numel(unreadable), strjoin(unreadable, ' '));
    end
    % only cache complete runs, so rerun datasets are picked up next time
    if isinf(max_datasets) && isempty(unreadable)
        save(res_file, 'res', 'EEG', '-v7.3')
    end
end
if isempty(res)
    error('run_paper_sw_plots:NoData', ['No dataset could be converted to res; ' ...
        'see the "skipped <id>: ..." lines above for the reason per dataset.']);
end
%% one recording per participant (same rule as the old analysis)
[~, list_idx] = ismember({res.pp}, list_ids);
participant_ids = list_participants(list_idx)';
[res,selected_pps,s] = participant_selection(res, 'durations_file', sprintf('%s/durations.txt',plot_data_path), ...
    'participant_ids', participant_ids);
fprintf('%d recordings selected for plotting: %s\n', numel(res), strjoin({res.pp}, ' '))
writecell({res.pp}', sprintf('%s/selected_recordings.txt',plot_data_path))
%% population plots
prepare_sw_data_for_plotting
%% individual plots
sw_to_behavior_plots
close all
fprintf('Figures saved in %s\n', figures_save_path)
