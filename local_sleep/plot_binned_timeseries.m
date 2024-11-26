function [] = plot_binned_timeseries(data_path, channels, options)
% plot_binned_timeseries Computes and plots binned slow-wave (SW) density/counts,
% amplitude, or both for participants, using separate binning for movie and phone conditions.
%
% Usage:
%   plot_binned_timeseries(data_path)
%   plot_binned_timeseries(data_path, channels)
%   plot_binned_timeseries(data_path, channels, options)
%
% Arguments:
%   data_path (char): Path to the data files.
%   channels (double, optional): Channels to include (default: 1:62).
%   options.sw_par (string, optional): Type of plot to generate ('dens', 'ampl', 'both'). Defaults to 'both'.
%   options.use_summary_file (logical, optional): Whether to use a summary file (default: false).

    arguments
        data_path char;
        channels double = 1:62;
        options.sw_par string {mustBeMember(options.sw_par, {'dens', 'ampl', 'both'})} = 'both';
        options.use_summary_file logical = false;
    end

    % Define separate directories for density and amplitude based on sw_par
    if strcmp(options.sw_par, 'dens') || strcmp(options.sw_par, 'both')
        density_dir = 'SW_Density_Timeseries';
        if ~exist(density_dir, 'dir')
            mkdir(density_dir);
        end
    end

    if strcmp(options.sw_par, 'ampl') || strcmp(options.sw_par, 'both')
        amplitude_dir = 'SW_Amplitude_Timeseries';
        if ~exist(amplitude_dir, 'dir')
            mkdir(amplitude_dir);
        end
    end

    % Initialize storage for data
    % Structure:
    % - Density/Counts:
    %   Column 1: Participant ID
    %   Column 2: Binned Movie Counts
    %   Column 3: Binned Phone Counts
    % - Amplitude:
    %   Column 1: Participant ID
    %   Column 2: Binned Movie Amplitudes
    %   Column 3: Binned Phone Amplitudes
    data_cell_array_dens = {};
    data_cell_array_ampl = {};
    participant_idx_dens = 0;
    participant_idx_ampl = 0;

    if options.use_summary_file
        % Load 'top10_SWs.mat' from 'data_path'
        loaded_data = load(fullfile(data_path, 'top10_SWs.mat'));
        if ~isfield(loaded_data, 'top10_SWs')
            error('The file top10_SWs.mat does not contain the variable top10_SWs.');
        end
        top10_SWs = loaded_data.top10_SWs;
        participant_ids_list = fieldnames(top10_SWs);

        for p = 1:length(participant_ids_list)
            participant_id = participant_ids_list{p};
            participant_data = top10_SWs.(participant_id);

            % Process Density/Counts if required
            if strcmp(options.sw_par, 'dens') || strcmp(options.sw_par, 'both')
                [average_counts_movie, average_counts_phone] = density_binning(participant_id, participant_data, channels, density_dir);
                % Collect density data
                participant_idx_dens = participant_idx_dens + 1;
                data_cell_array_dens{participant_idx_dens, 1} = participant_id;
                data_cell_array_dens{participant_idx_dens, 2} = average_counts_movie;
                data_cell_array_dens{participant_idx_dens, 3} = average_counts_phone;
            end

            % Process Amplitude if required
            if strcmp(options.sw_par, 'ampl') || strcmp(options.sw_par, 'both')
                [median_amplitudes_movie, median_amplitudes_phone] = amplitude_binning(participant_id, participant_data, channels, amplitude_dir);
                % Collect amplitude data
                participant_idx_ampl = participant_idx_ampl + 1;
                data_cell_array_ampl{participant_idx_ampl, 1} = participant_id;
                data_cell_array_ampl{participant_idx_ampl, 2} = median_amplitudes_movie;
                data_cell_array_ampl{participant_idx_ampl, 3} = median_amplitudes_phone;
            end
        end
    else
        % Load checkpoint files
        file_list = dir(fullfile(data_path, '*.mat'));
        file_names = {file_list.name};

        checkpoint_counter = 0;
        participant_counter = 0;

        top10_SWs = struct();

        for idx_file = 1:length(file_names)
            file_name = file_names{idx_file};

            checkpoint_counter = checkpoint_counter + 1;

            data = load(fullfile(data_path, file_name));

            %% PRINT FILE INFO

            fprintf('\n---------------------------------------------\n');
            fprintf('Checkpoint File: %s\n', file_name);
            fprintf('Checkpoint Number: %d/%d\n', checkpoint_counter, length(file_names));
            fprintf('---------------------------------------------\n\n');

            %% PROCESS EACH ENTRY

            if ~isfield(data, 'A')
                warning('File %s does not contain the field A. Skipping.', file_name);
                continue;
            end

            for idx = 1:length(data.A)

                load_data = data.A{idx};
                [movie_indexes, phone_indexes, ~, ~, ~] = seperate_movie_phone(load_data);

                if ~isempty(phone_indexes)

                    participant_counter = participant_counter + 1;

                    if participant_counter == 18
                        continue
                    end

                    if ~isfield(load_data{2}, 'filepath') || length(load_data{2}.filepath) < 4
                        warning('Participant %d has invalid filepath. Skipping.', participant_counter);
                        continue;
                    end

                    participant_id = sprintf('P%d_%s', participant_counter, load_data{2}.filepath(end-3:end));

                    if length(load_data) < 4
                        warning('Participant %s does not have enough data fields. Skipping.', participant_id);
                        continue;
                    end

                    top10_filtered_results = load_data{4};

                    % Get start and end times in samples
                    movie_start = movie_indexes{1}.movie_latencies(1);
                    movie_end = movie_indexes{1}.movie_latencies(end);
                    phone_start = phone_indexes{1}{1}(1);
                    phone_end = phone_indexes{1}{end}(end);

                    % Store participant's data and timing information in top10_SWs
                    participant_data.top10_filtered_results = top10_filtered_results;
                    participant_data.movie_start = movie_start;
                    participant_data.movie_end = movie_end;
                    participant_data.phone_start = phone_start;
                    participant_data.phone_end = phone_end;
                    participant_data.recording_end = load_data{2}.times(end);

                    top10_SWs.(participant_id) = participant_data;

                    % Process Density/Counts if required
                    if strcmp(options.sw_par, 'dens') || strcmp(options.sw_par, 'both')
                        [average_counts_movie, average_counts_phone] = density_binning(participant_id, participant_data, channels, density_dir);
                        % Collect density data
                        participant_idx_dens = participant_idx_dens + 1;
                        data_cell_array_dens{participant_idx_dens, 1} = participant_id;
                        data_cell_array_dens{participant_idx_dens, 2} = average_counts_movie;
                        data_cell_array_dens{participant_idx_dens, 3} = average_counts_phone;
                    end

                    % Process Amplitude if required
                    if strcmp(options.sw_par, 'ampl') || strcmp(options.sw_par, 'both')
                        [median_amplitudes_movie, median_amplitudes_phone] = amplitude_binning(participant_id, participant_data, channels, amplitude_dir);
                        % Collect amplitude data
                        participant_idx_ampl = participant_idx_ampl + 1;
                        data_cell_array_ampl{participant_idx_ampl, 1} = participant_id;
                        data_cell_array_ampl{participant_idx_ampl, 2} = median_amplitudes_movie;
                        data_cell_array_ampl{participant_idx_ampl, 3} = median_amplitudes_phone;
                    end

                else

                    fprintf('\n### Participant Tap Data Not Aligned ###\n\n');

                end % if ~isempty(phone_indexes)
            end % for idx = 1:length(data.A)
        end % for idx_file = 1:length(file_list)

        % Save 'top10_SWs.mat'
        save('top10_SWs.mat', 'top10_SWs', '-v7.3');
    end

    %% Save the data_cell_arrays based on sw_par
    if strcmp(options.sw_par, 'both')
        save('binned_SW_Density.mat', 'data_cell_array_dens');
        save('binned_SW_Amplitude.mat', 'data_cell_array_ampl');
    elseif strcmp(options.sw_par, 'dens')
        save('binned_SW_Density.mat', 'data_cell_array_dens');
    elseif strcmp(options.sw_par, 'ampl')
        save('binned_SW_Amplitude.mat', 'data_cell_array_ampl');
    end

end