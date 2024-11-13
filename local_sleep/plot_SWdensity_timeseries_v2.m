function [] = plot_SWdensity_timeseries_v2(data_path, channels)

arguments
    data_path char;
    channels double = 1:62;
end

output_dir = 'SW_Density_Timeseries_v3';
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

            %% Calculate the average incidence across selected channels

            % Define bin edges (1-minute bins in seconds)
            bin_edges_sec = movie_start_sec:60:phone_end_sec; % 60 seconds = 1 minute
            num_bins = length(bin_edges_sec) - 1;

            % Initialize an array to store the total counts across the selected channels
            total_counts = zeros(1, num_bins);

            % Loop through all channels and accumulate the counts
            for ch = channels
                % Extract 'maxnegpk' (positions of negative peaks in ms) for the specified channel
                maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;

                % Convert 'maxnegpk' data into seconds
                maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

                % Count the occurrences in each bin for the current channel
                [counts, ~] = histcounts(maxnegpk_seconds, bin_edges_sec);

                % Accumulate the counts across all channels
                total_counts = total_counts + counts;
            end

            % Calculate the average by dividing the total counts by the number of channels
            average_counts = total_counts / length(channels);

            %% Remove gap between movie and phone conditions

            % Calculate bin centers in minutes
            bin_centers_sec = bin_edges_sec(1:end-1) + diff(bin_edges_sec) / 2;
            bin_centers_min = bin_centers_sec / 60;
            bin_centers_adj = bin_centers_min - movie_start_min;

            % Calculate the gap duration in minutes
            gap_duration = phone_start_min_adj - movie_end_min_adj;

            % Identify indices of bins corresponding to the gap
            gap_bins = bin_centers_adj >= movie_end_min_adj & bin_centers_adj < phone_start_min_adj;
            
            % Remove gap bins from bin_centers_adj and average_counts
            bin_centers_adj_gapless = bin_centers_adj(~gap_bins);
            average_counts_gapless = average_counts(~gap_bins);

            % Adjust the time axis to remove the gap
            idx_after_gap = bin_centers_adj_gapless >= phone_start_min_adj;
            bin_centers_adj_gapless(idx_after_gap) = bin_centers_adj_gapless(idx_after_gap) - gap_duration;

            % Adjusted movie and phone start/end times
            movie_end_min_adj_gapless = movie_end_min_adj;
            phone_start_min_adj_gapless = phone_start_min_adj - gap_duration;
            phone_end_min_adj_gapless = phone_end_min_adj - gap_duration;

            % Find indices corresponding to the movie and phone conditions on the adjusted time axis
            movie_bins = bin_centers_adj_gapless >= 0 & bin_centers_adj_gapless < movie_end_min_adj_gapless;
            phone_bins = bin_centers_adj_gapless >= phone_start_min_adj_gapless & bin_centers_adj_gapless < phone_end_min_adj_gapless;

            % Calculate the average counts for each condition
            movie_avg_count = mean(average_counts_gapless(movie_bins));
            phone_avg_count = mean(average_counts_gapless(phone_bins));

            %% Plot the average incidence of slow waves across selected channels

            figure;
            plot(bin_centers_adj_gapless, average_counts_gapless, 'o-', 'LineWidth', 2, 'Color', [0.3 0.3 0.3]);
            xlabel('Time (minutes)');
            ylabel('Average Slow-Wave Count');
            title(sprintf('Average Slow-Wave Incidence per 1 Minute - %s', participant_id), 'Interpreter', 'none');
            grid on;

            % Plot vertical line at the end of the movie condition
            xline(movie_end_min_adj_gapless, 'Color', 'g', 'LineWidth', 2);

            % Plot horizontal line for the movie condition (from x = 0 to movie end)
            hold on;
            plot([0, movie_end_min_adj_gapless], [movie_avg_count, movie_avg_count], 'b--', 'LineWidth', 2);

            % Plot horizontal line for the phone condition (from movie end to the end of recording)
            plot([movie_end_min_adj_gapless, phone_end_min_adj_gapless], [phone_avg_count, phone_avg_count], 'r--', 'LineWidth', 2);

            legend('Average Counts', 'Movie End/Phone Start', 'Movie Average', 'Phone Average');

            filename = fullfile(output_dir, sprintf('SWdensity_timeseries_%s.png', participant_id));
            saveas(gcf, filename);
            close(gcf); % Close the figure to prevent too many open figures

        else

            fprintf('\n### Participant Tap Data Not Aligned ###\n\n');

        end % if ~isempty(phone_indexes)
    end % for idx = 1:length(data.A)
end % for idx_file = 1:length(file_list)

save('top10_SWs.mat', 'top10_SWs', '-v7.3');

end