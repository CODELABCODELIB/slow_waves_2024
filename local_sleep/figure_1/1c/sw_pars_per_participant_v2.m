function [sw_info, sw_pars] = sw_pars_per_participant_v2(data_path, chanlocs, options)
% Function to process slow-wave parameters per participant.
%
% This function loads EEG data, separates it into movie and phone conditions,
% computes slow-wave parameters, performs outlier detection and interpolation if required,
% and optionally visualizes the results.
%
% Inputs:
%   - data_path: Path to the directory containing .mat files with EEG data.
%   - chanlocs:  Struct containing channel locations.
%   - options:   Struct with the following optional fields:
%       - participant_stop:     (double) Number of participants to process before stopping.
%       - exclude_channels:     (double array) Channels to exclude from analysis.
%       - interpolate_outliers: (logical) Whether to interpolate outlier channels.
%       - visualize:            (logical) Whether to generate and save topographical plots.
%
% Outputs:
%   - sw_info: Struct containing comprehensive slow-wave information for each participant.
%   - sw_pars: Struct containing computed slow-wave parameters for each participant.

arguments
    data_path char;
    chanlocs struct = struct();
    options.participant_stop double = [];
    options.exclude_channels double = [];
    options.interpolate_outliers logical = 0;
    options.visualize logical = 1;
end

% Create directory for visualization outputs if visualization is enabled
if options.visualize
    if ~exist('Participant_Topoplots', 'dir')
        mkdir('Participant_Topoplots');
    end
end

% Get list of all .mat files in the specified data path
file_list = dir(fullfile(data_path, '*.mat'));
file_names = {file_list.name};

% Initialize counters and flags
checkpoint_counter = 0;
participant_counter = 0;
stop_loop = false;

% Loop through each file in the directory
for file_name = file_names

    checkpoint_counter = checkpoint_counter + 1;

    % Load data from the current file
    data = load(file_name{1});

    %% PRINT FILE INFO

    fprintf('\n---------------------------------------------\n');
    fprintf('Checkpoint File: %s\n', file_name{1});
    fprintf('Checkpoint Number: %d/%d\n', checkpoint_counter, length(file_names));
    fprintf('---------------------------------------------\n\n');

    %%

    % Loop through each data entry in the loaded file
    for idx = 1:length(data.A)

        % Extract the data for the current index
        load_data = data.A{idx};

        % Separate movie and phone indices from the data
        [movie_indexes, phone_indexes, ~, ~, ~] = seperate_movie_phone(load_data);

        % Proceed only if phone indexes are available
        if ~isempty(phone_indexes)

            % Increment participant counter and generate participant ID
            participant_counter = participant_counter + 1;
            participant_id = sprintf('P%d_%s', participant_counter, load_data{2}.filepath(end-3:end));

            % Create a subdirectory for participant-specific topoplots if visualization is enabled
            if options.visualize
                sub_dir_path = fullfile('Participant_Topoplots', participant_id);
                if ~exist(sub_dir_path, 'dir')
                    mkdir(sub_dir_path);
                end
            end

            % Load the top 10 filtered slow-wave results
            top10_filtered_results = load_data{4};
            fields = fieldnames(top10_filtered_results.channels);
            num_fields = length(fields);

            % Determine included and excluded channels
            num_channels = length(top10_filtered_results.channels);
            num_excl_channels = length(options.exclude_channels);
            num_incl_channels = num_channels - num_excl_channels;
            incl_channels = setdiff(1:num_channels, options.exclude_channels);

            % Initialize structures to store slow-wave information and parameters
            sw_info.(participant_id) = struct( ...
                'orig_movie_start', [], ...
                'orig_movie_end', [], ...
                'orig_phone_start', [], ...
                'orig_phone_end', [], ...
                'movie_start', [], ...
                'movie_end', [], ...
                'phone_start', [], ...
                'phone_end', [], ...
                'movie_waves', top10_filtered_results, ...
                'phone_waves', top10_filtered_results, ...
                'movie_phone_waves', top10_filtered_results);

            sw_pars.(participant_id) = struct( ...
                'condition_order', '', ...
                'wave_pars_movie', struct( ...
                    'wvspermin', zeros(1, num_incl_channels), ...
                    'p2pamp', zeros(1, num_incl_channels), ...
                    'dslope', zeros(1, num_incl_channels), ...
                    'uslope', zeros(1, num_incl_channels)), ...
                'wave_pars_phone', struct( ...
                    'wvspermin', zeros(1, num_incl_channels), ...
                    'p2pamp', zeros(1, num_incl_channels), ...
                    'dslope', zeros(1, num_incl_channels), ...
                    'uslope', zeros(1, num_incl_channels)), ...
                'wave_pars_overall', struct( ...
                    'wvspermin', zeros(1, num_incl_channels), ...
                    'p2pamp', zeros(1, num_incl_channels), ...
                    'dslope', zeros(1, num_incl_channels), ...
                    'uslope', zeros(1, num_incl_channels)));

            % Extract start and end times for movie and phone conditions
            movie_start = movie_indexes{1}.movie_latencies(1);
            movie_end = movie_indexes{1}.movie_latencies(end);
            phone_start = phone_indexes{1}{1}(1);
            phone_end = phone_indexes{1}{end}(end);

            % Store the original start and end times
            sw_info.(participant_id).orig_movie_start = movie_start;
            sw_info.(participant_id).orig_movie_end = movie_end;
            sw_info.(participant_id).orig_phone_start = phone_start;
            sw_info.(participant_id).orig_phone_end = phone_end;

            % Determine the condition order and adjust end times if necessary
            if movie_start < phone_start

                sw_pars.(participant_id).condition_order = 'movie_phone';

                if movie_end > phone_start
                    movie_end = phone_start;
                end

            elseif phone_start < movie_start

                sw_pars.(participant_id).condition_order = 'phone_movie';

                if phone_end > movie_start
                    phone_end = movie_start;
                end

            end

            % Store the adjusted start and end times
            sw_info.(participant_id).movie_start = movie_start;
            sw_info.(participant_id).movie_end = movie_end;
            sw_info.(participant_id).phone_start = phone_start;
            sw_info.(participant_id).phone_end = phone_end;

            % Calculate the lengths of movie and phone conditions
            movie_length = movie_end - movie_start;
            phone_length = phone_end - phone_start;

            % Loop through each channel to filter slow waves based on conditions
            for ch = 1:num_channels
                % Extract negative zero crossings for the current channel
                negzx = cell2mat(top10_filtered_results.channels(ch).negzx);

                % Determine indices to keep for movie, phone, and combined conditions
                idx_keep_movie = negzx >= movie_start & negzx < movie_end;
                idx_keep_phone = negzx >= phone_start & negzx < phone_end;
                idx_keep_movie_phone = (negzx >= movie_start & negzx < movie_end) | (negzx >= phone_start & negzx < phone_end);

                % Loop through each field to filter data accordingly
                for field_idx = 1:num_fields
                    field = fields{field_idx};
                    if strcmp(field, 'datalength')
                        % Set the data length for each condition
                        sw_info.(participant_id).movie_waves.channels(ch).(field) = movie_length;
                        sw_info.(participant_id).phone_waves.channels(ch).(field) = phone_length;
                        sw_info.(participant_id).movie_phone_waves.channels(ch).(field) = movie_length + phone_length;
                    else
                        % Filter the data based on the indices for each condition
                        sw_info.(participant_id).movie_waves.channels(ch).(field) = sw_info.(participant_id).movie_waves.channels(ch).(field)(idx_keep_movie);
                        sw_info.(participant_id).phone_waves.channels(ch).(field) = sw_info.(participant_id).phone_waves.channels(ch).(field)(idx_keep_phone);
                        sw_info.(participant_id).movie_phone_waves.channels(ch).(field) = sw_info.(participant_id).movie_phone_waves.channels(ch).(field)(idx_keep_movie_phone);
                    end
                end
            end

            %% PRINT PARTICIPANT INFO %%

            fprintf('\n---------------------------------------------\n');

            fprintf('Participant: %s\n\n', participant_id);

            % Display condition times and lengths based on the condition order
            if strcmp(sw_pars.(participant_id).condition_order, 'movie_phone')
                        
                fprintf('Movie start: %.1f min\n', movie_start / 1000 / 60);
                fprintf('Movie end: %.1f min\n', movie_end / 1000 / 60);
                fprintf('Phone start: %.1f min\n', phone_start / 1000 / 60);
                fprintf('Phone end: %.1f min\n\n', phone_end / 1000 / 60);
        
                fprintf('Movie length: %.1f min\n', movie_length / 1000 / 60);
                fprintf('Phone length: %.1f min\n\n', phone_length / 1000 / 60);

            elseif strcmp(sw_pars.(participant_id).condition_order, 'phone_movie')

                fprintf('Phone start: %.1f min\n', phone_start / 1000 / 60);
                fprintf('Phone end: %.1f min\n', phone_end / 1000 / 60);
                fprintf('Movie start: %.1f min\n', movie_start / 1000 / 60);
                fprintf('Movie end: %.1f min\n\n', movie_end / 1000 / 60);

                fprintf('Phone length: %.1f min\n\n', phone_length / 1000 / 60);
                fprintf('Movie length: %.1f min\n', movie_length / 1000 / 60);

            end

            fprintf('Recording end: %.1f min\n', load_data{2}.times(end) / 1000 / 60);

            fprintf('---------------------------------------------\n\n');

            %%

            % Set the original sampling frequency
            fs_orig = 1000;

            % Compute wave parameters for movie, phone, and overall conditions
            tmp.wave_pars_movie = compute_wave_pars_new_v2(sw_info.(participant_id).movie_waves, fs_orig, 'channels', incl_channels);
            tmp.wave_pars_phone = compute_wave_pars_new_v2(sw_info.(participant_id).phone_waves, fs_orig, 'channels', incl_channels);
            tmp.wave_pars_overall = compute_wave_pars_new_v2(sw_info.(participant_id).movie_phone_waves, fs_orig, 'channels', incl_channels);

            %% OUTLIER DETECTION & INTERPOLATION

            % Perform outlier detection and interpolation if enabled
            if options.interpolate_outliers

                % Get field names of the temporary container for the condition-wise wave parameters
                tmp_fields = fieldnames(tmp);
                num_tmp_fields = length(tmp_fields);
        
                % Get field names of the condition-wise wave parameters
                pars_fields = fieldnames(tmp.wave_pars_movie);
                num_pars_fields = length(pars_fields);
        
                % Loop through each temporary field (movie, phone, overall)
                for tmp_idx = 1:num_tmp_fields
        
                    tmp_field = tmp_fields{tmp_idx};
        
                    % Loop through each parameter field (e.g., wvspermin)
                    for pars_idx = 1:num_pars_fields
        
                        pars_field = pars_fields{pars_idx};
        
                        pars_vals = tmp.(tmp_field).(pars_field);
                        
                        % Perform Box-Cox transformation to normalize data
                        lambda_opt = estimate_lambda(pars_vals);
                        transformed_pars_vals = boxcox_transform(pars_vals, lambda_opt);
                        
                        % Perform z-standardization
                        z_transformed_pars_vals = (transformed_pars_vals - mean(transformed_pars_vals)) / std(transformed_pars_vals);
                        
                        % Compute absolute z-values for outlier detection
                        abs_z_transformed_pars_vals = abs(z_transformed_pars_vals);
                        
                        % Set z-score threshold (99% confidence interval)
                        z_threshold = 2.58;
                        
                        % Identify outliers exceeding the z-score threshold
                        outliers = abs_z_transformed_pars_vals > z_threshold;
        
                        if any(outliers)

                            fprintf('\n+++ %d Outlier(s) detected in "%s": %s +++\n\n', sum(outliers), tmp_field, pars_field);
                            
                            % Get indices of bad channels
                            bad_channels = find(outliers);
                            
                            % Initialize interpolated values with original parameter values
                            interpolated_values = pars_vals;
                            
                            % Prepare the EEG structure for interpolation
                            EEG = eeg_emptyset;
                            EEG.data = pars_vals';
                            EEG.nbchan = num_incl_channels;
                            EEG.chanlocs = chanlocs(incl_channels);
                            EEG.srate = 1;  % Dummy sample rate for interpolation
                            EEG.pnts = 1;
                            EEG.trials = 1;
                            EEG.times = 0;
                            EEG.xmin = 0;
                            EEG.xmax = 0;
                            
                            % Mark bad channels with NaN
                            EEG.data(bad_channels) = NaN;
                            
                            % Perform spherical spline interpolation
                            EEG_interp = eeg_interp(EEG, bad_channels, 'spherical');
                            
                            % Replace outlier values with interpolated values
                            interpolated_values(bad_channels) = EEG_interp.data(bad_channels);
                            
                            % Update the condition-wise wave parameters with interpolated values
                            tmp.(tmp_field).(pars_field) = interpolated_values;

                        end

                    end

                end

            end

            %%

            % Assign computed wave parameters to the participant's structure
            sw_pars.(participant_id).wave_pars_movie.wvspermin = tmp.wave_pars_movie.wvspermin;
            sw_pars.(participant_id).wave_pars_movie.p2pamp = tmp.wave_pars_movie.p2pamp;
            sw_pars.(participant_id).wave_pars_movie.dslope = tmp.wave_pars_movie.dslope;
            sw_pars.(participant_id).wave_pars_movie.uslope = tmp.wave_pars_movie.uslope;
                
            sw_pars.(participant_id).wave_pars_phone.wvspermin = tmp.wave_pars_phone.wvspermin;
            sw_pars.(participant_id).wave_pars_phone.p2pamp = tmp.wave_pars_phone.p2pamp;
            sw_pars.(participant_id).wave_pars_phone.dslope = tmp.wave_pars_phone.dslope;
            sw_pars.(participant_id).wave_pars_phone.uslope = tmp.wave_pars_phone.uslope;
                
            sw_pars.(participant_id).wave_pars_overall.wvspermin = tmp.wave_pars_overall.wvspermin;
            sw_pars.(participant_id).wave_pars_overall.p2pamp = tmp.wave_pars_overall.p2pamp;
            sw_pars.(participant_id).wave_pars_overall.dslope = tmp.wave_pars_overall.dslope;
            sw_pars.(participant_id).wave_pars_overall.uslope = tmp.wave_pars_overall.uslope;

            % Generate topographical visualizations if enabled
            if options.visualize
                visualize_wave_pars_new_v2(tmp.wave_pars_movie, chanlocs(incl_channels), 'm', sub_dir_path);
                visualize_wave_pars_new_v2(tmp.wave_pars_phone, chanlocs(incl_channels), 'p', sub_dir_path);
                visualize_wave_pars_new_v2(tmp.wave_pars_overall, chanlocs(incl_channels), 'o', sub_dir_path);
            end

            % Check if the participant stop condition is met
            if ~isempty(options.participant_stop) && participant_counter >= options.participant_stop
                stop_loop = true;
                break;
            end

        else

            fprintf('\n### Participant Tap Data Not Aligned ###\n\n');

        end

    end

    % Exit the loop if the stop condition is met
    if stop_loop
        break;
    end

end

end