%% Configuration

pipeline_dir = fileparts(mfilename('fullpath'));
addpath(pipeline_dir);

config.input_directory = '/Users/davidhof/Downloads/SW x Blinks';
config.file_pattern = '*.set';
config.dataset_files = {};  % Empty: all matching files in input_directory.
% Explicit list: config.dataset_files = {'/data/P01.set', '/data/P02.set'};
config.dataset_ids = {};    % Empty: filenames without .set; IDs must be unique.
config.output_directory = fullfile(pipeline_dir, 'Outputs');
config.continue_on_error = true;

config.ocular_method = 'refined';  % 'old' or 'refined'.
config.enable_speedup = true;
config.speedup_working_srate = 256;
config.icablinkmetrics_path = ...
    '/Users/davidhof/Downloads/SW x Blinks/icablinkmetrics3.2';
config.manual_ica_reject_comps = {};  % Optional cell array, one entry per dataset.

config.refined = refined_ocular_defaults();
config.refined.min_abs_corr_broadband = 0.50;
config.refined.min_abs_corr_slow = 0.50;
config.refined.event_threshold_sd = 5.0;
config.refined.veog_positive = {'E35', 'E49'};
config.refined.veog_negative = {'E63', 'E64'};
config.refined.heog_positive = {'E60'};
config.refined.heog_negative = {'E50'};
config.refined_ica_mode = 'auto';  % 'auto': reuse or train; 'reuse'; 'train'.
config.ica_cache_directory = fullfile(pipeline_dir, 'ICA_Cache');
config.ica_report_files = {};  % Optional prior report paths, one per dataset.

config.save_topoplots = true;
config.show_topoplots = false;
config.save_preprocessed_EEG = false;
config.save_cleaned_EEG = false;  % Ocular-corrected, interpolated EEG at the working rate.

% Optional overrides set by a calling script (e.g. alice/run_sw_pipeline_alice.m).
if exist('config_overrides', 'var')
    for field = fieldnames(config_overrides)'
        config.(field{1}) = config_overrides.(field{1});
    end
end
if ~isfield(config, 'batch_summary_file')
    config.batch_summary_file = fullfile(config.output_directory, 'batch_summary.csv');
end

[dataset_files, dataset_ids] = prepare_sw_batch(config);
batch_summary = repmat(struct('dataset_id', '', 'input_file', '', 'method', '', ...
    'status', 'not_run', 'output_directory', '', 'ica_report_file', '', ...
    'ica_reused', false, 'elapsed_seconds', NaN, 'error_identifier', '', ...
    'error_message', ''), numel(dataset_files), 1);
if exist(config.output_directory, 'dir') ~= 7
    mkdir(config.output_directory);
end

%% Add icablinkmetrics toolbox to path

icablinkmetrics_path = config.icablinkmetrics_path;
if strcmp(config.ocular_method, 'old')
    if exist(icablinkmetrics_path, 'dir')
        addpath(genpath(icablinkmetrics_path));
        fprintf('Added icablinkmetrics toolbox to MATLAB path:\n%s\n', icablinkmetrics_path);
    elseif exist('icablinkmetrics', 'file') ~= 2 && isempty(config.manual_ica_reject_comps)
        error('swpipeline:MissingBlinkToolbox', 'icablinkmetrics is not available.');
    end
end

%% Batch processing

for dataset_idx = 1:numel(dataset_files)
    clear EEG_sw preprocessed_EEG results top10_filtered_results wave_pars;
    clear refined_ocular_report derivations Rej_Comp recording_info;
    dataset_clock = tic;
    dataset_id = dataset_ids{dataset_idx};
    dataset_directory = fullfile(config.output_directory, dataset_id, config.ocular_method);
    batch_summary(dataset_idx).dataset_id = dataset_id;
    batch_summary(dataset_idx).input_file = dataset_files{dataset_idx};
    batch_summary(dataset_idx).method = config.ocular_method;
    batch_summary(dataset_idx).output_directory = dataset_directory;
    fprintf('\nDataset %d/%d: %s (%s)\n', dataset_idx, numel(dataset_files), ...
        dataset_id, config.ocular_method);

    try
        if exist(dataset_directory, 'dir') ~= 7
            mkdir(dataset_directory);
        end
        result_file = fullfile(dataset_directory, 'wave_results.mat');

        %% Load dataset

        EEG_sw = pop_loadset(dataset_files{dataset_idx});
        native_srate = EEG_sw.srate;
        source_xmin = EEG_sw.xmin;

        % Recording metadata (events, taps, lengths) on the native clock for
        % the downstream SW-to-behaviour analyses.
        recording_info = struct('source_file', dataset_files{dataset_idx}, ...
            'filename', EEG_sw.filename, 'filepath', EEG_sw.filepath, ...
            'srate', EEG_sw.srate, 'pnts', EEG_sw.pnts, 'xmin', EEG_sw.xmin, ...
            'nbchan', EEG_sw.nbchan, 'chanlocs', EEG_sw.chanlocs);
        recording_info.event = EEG_sw.event;
        recording_info.urevent = EEG_sw.urevent;
        optional_fields = {'Orignalchanlocs', 'Originalchanlocs', 'Aligned'};
        for k = 1:numel(optional_fields)
            if isfield(EEG_sw, optional_fields{k})
                recording_info.(optional_fields{k}) = EEG_sw.(optional_fields{k});
            end
        end
        recording_info.tap_samples = [];
        if isfield(EEG_sw, 'Aligned') && isfield(EEG_sw.Aligned, 'BS_to_tap') && ...
                isfield(EEG_sw.Aligned.BS_to_tap, 'Phone')
            recording_info.tap_samples = find(EEG_sw.Aligned.BS_to_tap.Phone == 1);
        end

        if EEG_sw.trials ~= 1
            error('swpipeline:ContinuousDataRequired', 'Continuous EEG is required.');
        end
        if strcmp(config.ocular_method, 'refined')
            derivations = resolve_ocular_derivations(EEG_sw, config.refined);
        end

        %% Technical cleaning / ICA blink removal

        fprintf('Applying technical cleaning step...\n');
        EEG_sw = prepare_channels(EEG_sw, {'x_dir', 'y_dir', 'z_dir'}, false);
        if config.enable_speedup
            EEG_sw = eeg_timing('downsample', EEG_sw, config.speedup_working_srate);
            source_time_mapping = EEG_sw.etc.source_resampling_map;
        else
            source_time_mapping = eeg_timing('map', EEG_sw, EEG_sw.srate, EEG_sw.pnts);
        end
        Rej_Comp = [];

        if strcmp(config.ocular_method, 'refined')
            dataset = struct('id', dataset_id, 'index', dataset_idx, ...
                'directory', dataset_directory, 'source_file', dataset_files{dataset_idx});
            [EEG_sw, Rej_Comp, refined_ocular_report] = remove_refined_ocular_artifacts( ...
                EEG_sw, derivations, config, dataset);
            batch_summary(dataset_idx).ica_report_file = ...
                refined_ocular_report.options.ica_report_file;
            batch_summary(dataset_idx).ica_reused = refined_ocular_report.ica_reused;
        else
            manual_ica_reject_comps = [];
            if ~isempty(config.manual_ica_reject_comps)
                manual_ica_reject_comps = config.manual_ica_reject_comps{dataset_idx};
            end

            has_ica = isfield(EEG_sw, 'icaweights') && ...
                      ~isempty(EEG_sw.icaweights) && ...
                      isfield(EEG_sw, 'icasphere') && ...
                      ~isempty(EEG_sw.icasphere);

            has_icablinkmetrics = exist('icablinkmetrics', 'file') == 2;

            if has_ica && has_icablinkmetrics

                fprintf('icablinkmetrics found. Identifying blink-related ICA components...\n');

                idx_blink_chans = find( ...
                    strcmp({EEG_sw.chanlocs.labels}, 'E64') | ...
                    strcmp({EEG_sw.chanlocs.labels}, 'E63'));

                if isempty(idx_blink_chans)
                    error('swpipeline:MissingOcularChannels', 'E63/E64 are missing.');
                end

                rej = [];

                for i = 1:length(idx_blink_chans)

                    EEG_sw.icaquant{i} = icablinkmetrics(EEG_sw, ...
                        'ArtifactChannel', EEG_sw.data(idx_blink_chans(i), :), ...
                        'Alpha', 0.001, ...
                        'VisualizeData', 'False');

                    rej = [rej EEG_sw.icaquant{i}.identifiedcomponents]; %#ok<AGROW>
                end

                Rej_Comp = unique(rej);

                if ~isempty(Rej_Comp)
                    fprintf('Removing ICA components identified as blink-related: %s\n', ...
                        mat2str(Rej_Comp));

                    EEG_sw = pop_subcomp(EEG_sw, Rej_Comp, 0);
                    EEG_sw = eeg_checkset(EEG_sw);
                else
                    fprintf('No blink-related ICA components identified.\n');
                end

            elseif has_ica && ~isempty(manual_ica_reject_comps)

                fprintf('icablinkmetrics not available. Removing manually specified ICA components: %s\n', ...
                    mat2str(manual_ica_reject_comps));

                EEG_sw = pop_subcomp(EEG_sw, manual_ica_reject_comps, 0);
                EEG_sw = eeg_checkset(EEG_sw);

            elseif has_ica && ~has_icablinkmetrics

                error('swpipeline:MissingBlinkToolbox', ...
                    'ICA fields are present, but icablinkmetrics is unavailable.');

            else

                error('swpipeline:MissingStoredICA', ...
                    'The old method requires ICA stored in the input dataset.');

            end
        end

        %% Remove ocular channels before interpolation / re-referencing

        EEG_sw = prepare_channels(EEG_sw, {'E63', 'E64'}, true);

        if config.save_cleaned_EEG
            cleaned_EEG = EEG_sw;
            cleaned_EEG.data = single(cleaned_EEG.data);
            cleaned_EEG.source_time_mapping = source_time_mapping;
            save(fullfile(dataset_directory, 'cleaned_EEG.mat'), 'cleaned_EEG', '-v7.3');
            clear cleaned_EEG;
        end

        %% Reference electrodes

        ref_labels = {'E52', 'E58'};
        all_labels = {EEG_sw.chanlocs.labels};
        [found, ref_idx] = ismember(ref_labels, all_labels);
        if ~all(found)
            error('swpipeline:MissingReference', 'E52 and E58 must both be present.');
        end

        %% Preprocessing and slow-wave detection

        preprocessed_EEG = preprocessing_complete(EEG_sw, 'ref_electrodes', ref_idx);
        time_mapping = eeg_timing('map', ...
            EEG_sw, preprocessed_EEG.srate, preprocessed_EEG.pnts);
        segments = [time_mapping.output_bounds(1:end-1)', ...
            time_mapping.output_bounds(2:end)' - 1];
        results = twalldetectnew_TA_v4(preprocessed_EEG.data, native_srate, 0, segments);
        results = eeg_timing('attach', results, time_mapping, source_time_mapping, source_xmin);
        top10_filtered_results = filter_results(results);
        wave_pars = compute_wave_pars(top10_filtered_results, native_srate);

        %% Save results

        chanlocs = preprocessed_EEG.chanlocs;
        processing_info = struct('dataset_id', dataset_id, ...
            'source_file', dataset_files{dataset_idx}, 'native_srate', native_srate, ...
            'working_srate', EEG_sw.srate, 'analysis_srate', preprocessed_EEG.srate, ...
            'ocular_method', config.ocular_method, 'removed_components', Rej_Comp, ...
            'configuration', config);
        save(result_file, 'results', 'top10_filtered_results', 'wave_pars', ...
            'chanlocs', 'processing_info', 'recording_info', '-v7.3');
        if config.save_preprocessed_EEG
            save(fullfile(dataset_directory, 'preprocessed_EEG.mat'), ...
                'preprocessed_EEG', '-v7.3');
        end
        if config.save_topoplots
            visualize_wave_pars(wave_pars, chanlocs, ...
                fullfile(dataset_directory, 'Topoplots'), config.show_topoplots);
        end
        batch_summary(dataset_idx).status = 'ok';
    catch ME
        batch_summary(dataset_idx).status = 'failed';
        batch_summary(dataset_idx).error_identifier = ME.identifier;
        batch_summary(dataset_idx).error_message = ME.message;
        fprintf(2, 'Failed %s: %s\n', dataset_id, ME.message);
        if exist(dataset_directory, 'dir') == 7
            error_report = getReport(ME, 'extended', 'hyperlinks', 'off');
            save(fullfile(dataset_directory, 'processing_error.mat'), 'error_report');
        end
        if ~config.continue_on_error
            batch_summary(dataset_idx).elapsed_seconds = toc(dataset_clock);
            writetable(struct2table(batch_summary), ...
                config.batch_summary_file);
            rethrow(ME);
        end
    end
    batch_summary(dataset_idx).elapsed_seconds = toc(dataset_clock);
    writetable(struct2table(batch_summary), config.batch_summary_file);
end
