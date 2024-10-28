function [sw_info, sw_pars] = sw_pars_per_participant_v2(data_path, chanlocs, options)

arguments
    data_path char;
    chanlocs struct = struct();
    options.participant_stop double = [];
    options.exclude_channels double = [];
    options.interpolate_outliers logical = 0;
    options.visualize logical = 1;
end

if options.visualize
    if ~exist('Participant_Topoplots', 'dir')
        mkdir('Participant_Topoplots');
    end
end

file_list = dir(fullfile(data_path, '*.mat'));
file_names = {file_list.name};

checkpoint_counter = 0;
participant_counter = 0;
stop_loop = false;

for file_name = file_names

    checkpoint_counter = checkpoint_counter + 1;

    data = load(file_name{1});

    %% PRINT FILE INFO

    fprintf('\n---------------------------------------------\n');
    fprintf('Checkpoint File: %s\n', file_name{1});
    fprintf('Checkpoint Number: %d/%d\n', checkpoint_counter, length(file_names));
    fprintf('---------------------------------------------\n\n');

    %%

    for idx = 1:length(data.A)

        load_data = data.A{idx};
        [movie_indexes, phone_indexes, ~, ~, ~] = seperate_movie_phone(load_data);

        if ~isempty(phone_indexes)

            participant_counter = participant_counter + 1;
            participant_id = sprintf('P%d_%s', participant_counter, load_data{2}.filepath(end-3:end));

            if options.visualize
                sub_dir_path = fullfile('Participant_Topoplots', participant_id);
                if ~exist(sub_dir_path, 'dir')
                    mkdir(sub_dir_path);
                end
            end

            top10_filtered_results = load_data{4};
            fields = fieldnames(top10_filtered_results.channels);
            num_fields = length(fields);

            num_channels = length(top10_filtered_results.channels);
            num_excl_channels = length(options.exclude_channels);
            num_incl_channels = num_channels - num_excl_channels;
            incl_channels = setdiff(1:num_channels, options.exclude_channels);

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

            movie_start = movie_indexes{1}.movie_latencies(1);
            movie_end = movie_indexes{1}.movie_latencies(end);
            phone_start = phone_indexes{1}{1}(1);
            phone_end = phone_indexes{1}{end}(end);

            sw_info.(participant_id).orig_movie_start = movie_start;
            sw_info.(participant_id).orig_movie_end = movie_end;
            sw_info.(participant_id).orig_phone_start = phone_start;
            sw_info.(participant_id).orig_phone_end = phone_end;

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

            sw_info.(participant_id).movie_start = movie_start;
            sw_info.(participant_id).movie_end = movie_end;
            sw_info.(participant_id).phone_start = phone_start;
            sw_info.(participant_id).phone_end = phone_end;

            movie_length = movie_end - movie_start;
            phone_length = phone_end - phone_start;

            for ch = 1:num_channels
                negzx = cell2mat(top10_filtered_results.channels(ch).negzx);
                idx_keep_movie = negzx >= movie_start & negzx < movie_end;
                idx_keep_phone = negzx >= phone_start & negzx < phone_end;
                idx_keep_movie_phone = (negzx >= movie_start & negzx < movie_end) | (negzx >= phone_start & negzx < phone_end);
                for field_idx = 1:num_fields
                    field = fields{field_idx};
                    if strcmp(field, 'datalength')
                        sw_info.(participant_id).movie_waves.channels(ch).(field) = movie_length;
                        sw_info.(participant_id).phone_waves.channels(ch).(field) = phone_length;
                        sw_info.(participant_id).movie_phone_waves.channels(ch).(field) = movie_length + phone_length;
                    else
                        sw_info.(participant_id).movie_waves.channels(ch).(field) = sw_info.(participant_id).movie_waves.channels(ch).(field)(idx_keep_movie);
                        sw_info.(participant_id).phone_waves.channels(ch).(field) = sw_info.(participant_id).phone_waves.channels(ch).(field)(idx_keep_phone);
                        sw_info.(participant_id).movie_phone_waves.channels(ch).(field) = sw_info.(participant_id).movie_phone_waves.channels(ch).(field)(idx_keep_movie_phone);
                    end
                end
            end

            %% PRINT PARTICIPANT INFO %%

            fprintf('\n---------------------------------------------\n');

            fprintf('Participant: %s\n\n', participant_id);

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

            fs_orig = 1000;

            tmp.wave_pars_movie = compute_wave_pars_new_v2(sw_info.(participant_id).movie_waves, fs_orig, 'channels', incl_channels);
            tmp.wave_pars_phone = compute_wave_pars_new_v2(sw_info.(participant_id).phone_waves, fs_orig, 'channels', incl_channels);
            tmp.wave_pars_overall = compute_wave_pars_new_v2(sw_info.(participant_id).movie_phone_waves, fs_orig, 'channels', incl_channels);

            %% OUTLIER DETECTION & INTERPOLATION

            if options.interpolate_outliers

                tmp_fields = fieldnames(tmp);
                num_tmp_fields = length(tmp_fields);
    
                pars_fields = fieldnames(tmp.wave_pars_movie);
                num_pars_fields = length(pars_fields);
    
                for tmp_idx = 1:num_tmp_fields
    
                    tmp_field = tmp_fields{tmp_idx};
    
                    for pars_idx = 1:num_pars_fields
    
                        pars_field = pars_fields{pars_idx};
    
                        pars_vals = tmp.(tmp_field).(pars_field);
                        
                        % Perform Box-Cox transformation
                        lambda_opt = estimate_lambda(pars_vals);
                        transformed_pars_vals = boxcox_transform(pars_vals, lambda_opt);
                        
                        % Perform z-standardization
                        z_transformed_pars_vals = (transformed_pars_vals - mean(transformed_pars_vals)) / std(transformed_pars_vals);
                        
                        % Compute absolute z-values
                        abs_z_transformed_pars_vals = abs(z_transformed_pars_vals);
                        
                        % Set z-score threshold
                        z_threshold = 2.58;
                        
                        % Identify outliers
                        outliers = abs_z_transformed_pars_vals > z_threshold;
    
                        if any(outliers)

                            fprintf('\n+++ %d Outlier(s) detected in "%s": %s +++\n\n', sum(outliers), tmp_field, pars_field);
                        
                            bad_channels = find(outliers);
                        
                            % Initialize interpolated_values with original pars_vals
                            interpolated_values = pars_vals;
                        
                            % Prepare the EEG structure for eeg_interp
                            EEG = eeg_emptyset;
                            EEG.data = pars_vals';
                            EEG.nbchan = num_incl_channels;
                            EEG.chanlocs = chanlocs(incl_channels);
                            EEG.srate = 1;  % Dummy sample rate
                            EEG.pnts = 1;
                            EEG.trials = 1;
                            EEG.times = 0;
                            EEG.xmin = 0;
                            EEG.xmax = 0;
                        
                            % Set bad channels data to NaN
                            EEG.data(bad_channels) = NaN;
                        
                            % Attempt spherical spline interpolation using eeg_interp
                            EEG_interp = eeg_interp(EEG, bad_channels, 'spherical');
                        
                            % Extract interpolated values
                            interpolated_values(bad_channels) = EEG_interp.data(bad_channels);
                            
                            tmp.(tmp_field).(pars_field) = interpolated_values;
    
                        end
    
                    end
    
                end

            end

            %%

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

            if options.visualize
                visualize_wave_pars_new_v2(tmp.wave_pars_movie, chanlocs(incl_channels), 'm', sub_dir_path);
                visualize_wave_pars_new_v2(tmp.wave_pars_phone, chanlocs(incl_channels), 'p', sub_dir_path);
                visualize_wave_pars_new_v2(tmp.wave_pars_overall, chanlocs(incl_channels), 'o', sub_dir_path);
            end

            if ~isempty(options.participant_stop) && participant_counter >= options.participant_stop
                stop_loop = true;
                break;
            end

        else

            fprintf('\n### Participant Tap Data Not Aligned ###\n\n');

        end

    end

    if stop_loop
        break;
    end

end

end