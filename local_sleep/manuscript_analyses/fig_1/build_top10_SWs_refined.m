function top10_SWs = build_top10_SWs_refined(output_root, target_path)
% Builds the 'top10_SWs.mat' summary of sw_pars_per_participant_v3 (Mode 1)
% from the refined SW pipeline outputs instead of the old checkpoint files.
% Afterwards run sw_pars_per_participant_v3(target_path, true, chanlocs, ...)
% (Mode 2).
%
% Usage:
%   top10_SWs = build_top10_SWs_refined(output_root, target_path)
% Inputs:
%   output_root (char)
%       SW_OUTPUT_DIR of the run (dataset_list.txt, Outputs/<id>/refined/wave_results.mat)
%   target_path (char)
%       Directory where 'top10_SWs.mat' is saved.
% Outputs:
%   top10_SWs (struct)
%       One field per participant (participant folder, e.g. AT08) with the same
%       fields as Mode 1 of sw_pars_per_participant_v3.
% Selection rules (same as sw_pars_per_participant_v3 Mode 1): movie before
% phone, movie end clipped to phone start, movie < 80 min, phone >= 15 min,
% and per participant the recording with the longest phone period.
% Requirements:
%   refined_eeg_stub, seperate_movie_phone (src/) and EEGLAB must be in MATLAB's path.

arguments
    output_root char;
    target_path char;
end

% Participant folder per dataset id (same ID rule as run_sw_pipeline_alice.m)
dataset_list = strtrim(splitlines(fileread(fullfile(output_root, 'dataset_list.txt'))));
dataset_list = dataset_list(~cellfun('isempty', dataset_list));
list_ids = regexprep(regexprep(dataset_list, '\.set$', ''), '[^A-Za-z0-9_.-]', '_');
list_participants = cellfun(@(x) strtok(x, '/'), dataset_list, 'UniformOutput', false);

top10_SWs = struct();
result_files = dir(fullfile(output_root, 'Outputs', '*', 'refined', 'wave_results.mat'));
for i = 1:numel(result_files)
    wave_file = fullfile(result_files(i).folder, result_files(i).name);
    dataset_id = regexp(wave_file, '[\\/]Outputs[\\/]([^\\/]+)[\\/]refined[\\/]', 'tokens', 'once');
    dataset_id = dataset_id{1};
    list_idx = find(strcmp(list_ids, dataset_id), 1);
    if isempty(list_idx)
        fprintf('\nSkipping %s: not in dataset_list.txt.\n', dataset_id);
        continue;
    end
    pid = matlab.lang.makeValidName(list_participants{list_idx});
    fprintf('\n%d/%d %s (participant %s)\n', i, numel(result_files), dataset_id, pid);

    try
        tmp = load(wave_file, 'top10_filtered_results', 'recording_info');
    catch ME
        fprintf('\nSkipping %s: cannot read wave_results.mat (%s).\n', dataset_id, ME.message);
        continue;
    end
    if tmp.recording_info.srate ~= 1000
        fprintf('\nSkipping %s: native srate %g Hz, the limits below assume 1000 Hz.\n', ...
            dataset_id, tmp.recording_info.srate);
        continue;
    end

    % Separate movie and phone indices (same function as Mode 1)
    EEG = refined_eeg_stub(tmp.recording_info);
    try
        [movie_indexes, phone_indexes, ~, ~, taps] = seperate_movie_phone({dataset_id, EEG, [], tmp.top10_filtered_results});
    catch ME
        fprintf('\nSkipping %s: seperate_movie_phone failed (%s).\n', dataset_id, ME.message);
        continue;
    end
    if isempty(movie_indexes) || isempty(movie_indexes{1}) || ~isfield(movie_indexes{1}, 'movie_latencies')
        fprintf('\nSkipping %s due to missing movie indexes.\n', dataset_id);
        continue;
    end
    if isempty(phone_indexes) || isempty(phone_indexes{1}) || isempty(taps{1})
        fprintf('\nSkipping %s due to missing phone indexes / taps.\n', dataset_id);
        continue;
    end

    participant_data = struct();
    participant_data.checkpoint_filename = dataset_id;
    participant_data.eeg_filename = '';
    participant_data.eeg_filepath = '';
    if isfield(tmp.recording_info, 'filename'); participant_data.eeg_filename = tmp.recording_info.filename; end
    if isfield(tmp.recording_info, 'filepath'); participant_data.eeg_filepath = tmp.recording_info.filepath; end
    participant_data.top10_filtered_results = tmp.top10_filtered_results;
    participant_data.taps = taps{1};
    participant_data.movie_start = movie_indexes{1}.movie_latencies(1);
    participant_data.movie_end = movie_indexes{1}.movie_latencies(end);
    participant_data.phone_start = phone_indexes{1}{1}(1);
    participant_data.phone_end = phone_indexes{1}{end}(end);
    participant_data.recording_end = EEG.times(end);

    % Require condition order movie_phone
    if participant_data.movie_start >= participant_data.phone_start
        fprintf('\nSkipping %s due to condition order not being movie_phone.\n', dataset_id);
        continue;
    end
    % Adjust movie end time if necessary
    if participant_data.movie_end > participant_data.phone_start
        participant_data.movie_end = participant_data.phone_start;
    end
    movie_length = participant_data.movie_end - participant_data.movie_start;
    phone_length = participant_data.phone_end - participant_data.phone_start;
    % Skip if movie longer than 80 min (4 800 000 ms)
    if movie_length >= 4800000
        fprintf('\nSkipping %s due to excessive movie length.\n', dataset_id);
        continue;
    end
    % Skip if phone shorter than 15 min (900 000 ms)
    if phone_length < 900000
        fprintf('\nSkipping %s due to short phone length.\n', dataset_id);
        continue;
    end
    participant_data.phone_length = phone_length;

    % Per participant keep the recording with the longest phone condition
    if ~isfield(top10_SWs, pid)
        top10_SWs.(pid) = participant_data;
        fprintf('\nStored %s for participant %s with phone length %.1f min.\n', dataset_id, pid, phone_length/1000/60);
    elseif participant_data.phone_length > top10_SWs.(pid).phone_length
        top10_SWs.(pid) = participant_data;
        fprintf('\nUpdated participant %s with %s, longer phone length %.1f min.\n', pid, dataset_id, phone_length/1000/60);
    else
        fprintf('\nDiscarded %s for participant %s with phone length %.1f min.\n', dataset_id, pid, phone_length/1000/60);
    end
end

if ~exist(target_path, 'dir'); mkdir(target_path); end
summary_file_path = fullfile(target_path, 'top10_SWs.mat');
save(summary_file_path, 'top10_SWs', '-v7.3');
fprintf('\nSaved top10_SWs (%d participants) to %s\n', numel(fieldnames(top10_SWs)), summary_file_path);
end
