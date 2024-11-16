function [] = plot_SWamplitude_timeseries(data_path, channels)

arguments
    data_path char;
    channels double = 1:62;
end

output_dir = 'SW_Amplitude_Timeseries';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

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

    %%

    for idx = 1:length(data.A)

        load_data = data.A{idx};
        [movie_indexes, phone_indexes, ~, ~, ~] = seperate_movie_phone(load_data);

        if ~isempty(phone_indexes)

            participant_counter = participant_counter + 1;

            if participant_counter == 18
                continue
            end

            participant_id = sprintf('P%d_%s', participant_counter, load_data{2}.filepath(end-3:end));

            top10_filtered_results = load_data{4};
            top10_SWs.(participant_id) = top10_filtered_results;

            num_channels = length(top10_filtered_results.channels);

            % Get start and end times in samples
            movie_start = movie_indexes{1}.movie_latencies(1);
            movie_end = movie_indexes{1}.movie_latencies(end);
            phone_start = phone_indexes{1}{1}(1);
            phone_end = phone_indexes{1}{end}(end);

            % Adjust movie and phone end times if they overlap
            if movie_start < phone_start

                if movie_end > phone_start
                    movie_end = phone_start;
                end

            elseif phone_start < movie_start
                if phone_end > movie_start
                    phone_end = movie_start;
                end

            end

            % Convert times to seconds and minutes
            movie_start_sec = movie_start / 1000;
            movie_start_min = movie_start_sec / 60;

            movie_end_sec = movie_end / 1000;
            movie_end_min = movie_end_sec / 60;
            movie_end_min_adj = movie_end_min - movie_start_min;

            phone_start_sec = phone_start / 1000;
            phone_start_min = phone_start_sec / 60;
            phone_start_min_adj = phone_start_min - movie_start_min;

            phone_end_sec = phone_end / 1000;
            phone_end_min = phone_end_sec / 60;
            phone_end_min_adj = phone_end_min - movie_start_min;

            movie_length = movie_end - movie_start;
            phone_length = phone_end - phone_start;

            % Adjust channels data
            for ch = 1:num_channels
                negzx = cell2mat(top10_filtered_results.channels(ch).negzx);
                idx_keep_movie_phone = (negzx >= movie_start & negzx < movie_end) | (negzx >= phone_start & negzx < phone_end);

                channel_fields = fieldnames(top10_filtered_results.channels(ch));
                for field_idx = 1:length(channel_fields)
                    field = channel_fields{field_idx};
                    if strcmp(field, 'datalength')
                        top10_filtered_results.channels(ch).(field) = movie_length + phone_length;
                    else
                        field_data = top10_filtered_results.channels(ch).(field);
                        top10_filtered_results.channels(ch).(field) = field_data(idx_keep_movie_phone);
                    end
                end
            end

            %% PRINT PARTICIPANT INFO %%

            fprintf('\n---------------------------------------------\n');

            fprintf('Participant: %s\n\n', participant_id);

            fprintf('Movie start: %.1f min\n', movie_start_min);
            fprintf('Movie end: %.1f min\n', movie_end_min);
            fprintf('Phone start: %.1f min\n', phone_start_min);
            fprintf('Phone end: %.1f min\n\n', phone_end_min);

            fprintf('Movie length: %.1f min\n', movie_length / 1000 / 60);
            fprintf('Phone length: %.1f min\n\n', phone_length / 1000 / 60);

            fprintf('Recording end: %.1f min\n', load_data{2}.times(end) / 1000 / 60);

            fprintf('---------------------------------------------\n\n');

            %% Calculate the median amplitude per bin across selected channels

            % Define bin edges (1-minute bins in seconds)
            bin_edges_sec = movie_start_sec:60:phone_end_sec; % 60 seconds = 1 minute
            num_bins = length(bin_edges_sec) - 1;

            % Initialize a cell array to store amplitudes per bin
            bin_amplitudes = cell(1, num_bins);

            % Loop through all channels
            for ch = channels
                % Extract 'maxnegpk' (positions of negative peaks in ms) for the specified channel
                maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;
                % Convert 'maxnegpk' data into seconds
                maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

                % Extract 'maxnegpkamp' and 'maxpospkamp' for the specified channel
                maxnegpkamp_data = top10_filtered_results.channels(ch).maxnegpkamp;
                maxpospkamp_data = top10_filtered_results.channels(ch).maxpospkamp;

                % Convert to arrays
                maxnegpkamp_values = cell2mat(maxnegpkamp_data);
                maxpospkamp_values = cell2mat(maxpospkamp_data);

                % Compute amplitudes
                amplitudes = abs(maxnegpkamp_values) + maxpospkamp_values;

                % For each wave, determine which bin it belongs to
                [~, ~, bin_indices] = histcounts(maxnegpk_seconds, bin_edges_sec);

                % Loop through waves and assign amplitudes to bins
                for i = 1:length(bin_indices)
                    bin_idx = bin_indices(i);
                    if bin_idx >= 1 && bin_idx <= num_bins
                        bin_amplitudes{bin_idx} = [bin_amplitudes{bin_idx}, amplitudes(i)];
                    end
                end
            end

            % Now, compute median amplitude per bin
            median_amplitudes = zeros(1, num_bins);
            for bin_idx = 1:num_bins
                if ~isempty(bin_amplitudes{bin_idx})
                    median_amplitudes(bin_idx) = median(bin_amplitudes{bin_idx});
                else
                    median_amplitudes(bin_idx) = NaN;
                end
            end

            %% Remove gap between movie and phone conditions

            % Calculate bin centers in minutes
            bin_centers_sec = bin_edges_sec(1:end-1) + diff(bin_edges_sec) / 2;
            bin_centers_min = bin_centers_sec / 60;
            bin_centers_adj = bin_centers_min - movie_start_min;

            % Calculate the gap duration in minutes
            gap_duration = phone_start_min_adj - movie_end_min_adj;

            % Identify indices of bins corresponding to the gap
            gap_bins = bin_centers_adj >= movie_end_min_adj & bin_centers_adj < phone_start_min_adj;

            % Remove gap bins from bin_centers_adj and median_amplitudes
            bin_centers_adj_gapless = bin_centers_adj(~gap_bins);
            median_amplitudes_gapless = median_amplitudes(~gap_bins);

            % Adjusted movie and phone start/end times
            movie_end_min_adj_gapless = movie_end_min_adj;
            phone_start_min_adj_gapless = phone_start_min_adj - gap_duration;
            phone_end_min_adj_gapless = phone_end_min_adj - gap_duration;

            % Adjust the time axis to remove the gap
            idx_after_gap = bin_centers_adj_gapless >= phone_start_min_adj_gapless;
            bin_centers_adj_gapless(idx_after_gap) = bin_centers_adj_gapless(idx_after_gap) - gap_duration;

            % Find indices corresponding to the movie and phone conditions on the adjusted time axis
            movie_bins = bin_centers_adj_gapless >= 0 & bin_centers_adj_gapless < movie_end_min_adj_gapless;
            phone_bins = bin_centers_adj_gapless >= movie_end_min_adj_gapless & bin_centers_adj_gapless < phone_end_min_adj_gapless;

            % Calculate the average median amplitude for each condition
            movie_avg_median_amplitude = mean(median_amplitudes_gapless(movie_bins), 'omitnan');
            phone_avg_median_amplitude = mean(median_amplitudes_gapless(phone_bins), 'omitnan');

            %% Plot the median amplitude of slow waves across selected channels

            figure;
            plot(bin_centers_adj_gapless, median_amplitudes_gapless, 'o-', 'LineWidth', 2, 'Color', [0.3 0.3 0.3]);
            xlabel('Time (minutes)');
            ylabel('Median Slow-Wave Amplitude (\muV)');
            title(sprintf('Median Slow-Wave Amplitude per 1 Minute - %s', participant_id), 'Interpreter', 'none');
            grid on;

            % Plot vertical line at the end of the movie condition
            xline(movie_end_min_adj_gapless, 'Color', 'g', 'LineWidth', 2);

            % Plot horizontal line for the movie condition (from x = 0 to movie end)
            hold on;
            plot([0, movie_end_min_adj_gapless], [movie_avg_median_amplitude, movie_avg_median_amplitude], 'b--', 'LineWidth', 2);

            % Plot horizontal line for the phone condition (from movie end to phone end)
            plot([movie_end_min_adj_gapless, phone_end_min_adj_gapless], [phone_avg_median_amplitude, phone_avg_median_amplitude], 'r--', 'LineWidth', 2);

            legend('Median Amplitudes', 'Movie End/Phone Start', 'Movie Average', 'Phone Average');

            filename = fullfile(output_dir, sprintf('SWamplitude_timeseries_%s.png', participant_id));
            saveas(gcf, filename);
            close(gcf); % Close the figure to prevent too many open figures

        else

            fprintf('\n### Participant Tap Data Not Aligned ###\n\n');

        end % if ~isempty(phone_indexes)
    end % for idx = 1:length(data.A)
end % for idx_file = 1:length(file_list)

% save('/data1/s3821013/top10_SWs.mat', 'top10_SWs', '-v7.3');

end