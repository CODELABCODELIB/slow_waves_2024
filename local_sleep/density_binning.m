function [counts_movie, counts_phone] = density_binning(participant_id, participant_data, channels, density_dir)
% density_binning Computes and plots SW density/counts for a participant.
%
% Usage:
%   [counts_movie, counts_phone] = density_binning(participant_id, participant_data, channels, density_dir)
%
% Arguments:
%   participant_id (char): Identifier for the participant.
%   participant_data (struct): Data associated with the participant.
%   channels (double): Channels to include in the analysis.
%   density_dir (char): Directory to save the density plots.
%
% Returns:
%   counts_movie (double): Binned counts during the movie condition.
%   counts_phone (double): Binned counts during the phone condition.

    % Extract relevant data
    top10_filtered_results = participant_data.top10_filtered_results;
    movie_start = participant_data.movie_start;
    movie_end = participant_data.movie_end;
    phone_start = participant_data.phone_start;
    phone_end = participant_data.phone_end;
    recording_end = participant_data.recording_end;

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
    num_channels = length(top10_filtered_results.channels);
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
    fprintf('Recording end: %.1f min\n', recording_end / 1000 / 60);
    fprintf('---------------------------------------------\n\n');

    %% Calculate the average incidence across selected channels %%

    % Define bin edges (1-minute bins in seconds)
    bin_edges_sec = movie_start_sec:60:phone_end_sec; % 60 seconds = 1 minute
    num_bins = length(bin_edges_sec) - 1;

    % Initialize a matrix to store counts per channel per bin
    channel_counts = zeros(length(channels), num_bins);

    % Loop through all channels and accumulate the counts
    channel_idx = 0;
    for ch = channels
        channel_idx = channel_idx + 1;
        % Extract 'maxnegpk' (positions of negative peaks in ms) for the specified channel
        maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;

        % Convert 'maxnegpk' data into seconds
        maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

        % Count the occurrences in each bin for the current channel
        counts = histcounts(maxnegpk_seconds, bin_edges_sec);

        % Store counts for each channel
        channel_counts(channel_idx, :) = counts;
    end

    % Calculate the average counts across channels
    average_counts = mean(channel_counts, 1);

    % Calculate the standard deviation across channels per bin
    std_counts = std(channel_counts, 0, 1);

    %% Remove gap between movie and phone conditions %%

    % Calculate bin centers in minutes
    bin_centers_sec = bin_edges_sec(1:end-1) + diff(bin_edges_sec) / 2;
    bin_centers_min = bin_centers_sec / 60;
    bin_centers_adj = bin_centers_min - movie_start_min;

    % Calculate the gap duration in minutes
    gap_duration = phone_start_min_adj - movie_end_min_adj;

    % Identify indices of bins corresponding to the gap
    gap_bins = bin_centers_adj >= movie_end_min_adj & bin_centers_adj < phone_start_min_adj;

    % Remove gap bins from bin_centers_adj and average_counts and std_counts
    bin_centers_adj_gapless = bin_centers_adj(~gap_bins);
    average_counts_gapless = average_counts(~gap_bins);
    std_counts_gapless = std_counts(~gap_bins);

    % Adjusted movie and phone start/end times
    movie_end_min_adj_gapless = movie_end_min_adj;
    phone_start_min_adj_gapless = phone_start_min_adj - gap_duration;
    phone_end_min_adj_gapless = phone_end_min_adj - gap_duration;

    % Adjust the time axis to remove the gap
    idx_after_gap = bin_centers_adj_gapless >= phone_start_min_adj_gapless;
    bin_centers_adj_gapless(idx_after_gap) = bin_centers_adj_gapless(idx_after_gap) - gap_duration;

    % Find indices corresponding to the movie and phone conditions on the adjusted time axis
    movie_bins = bin_centers_adj_gapless >= 0 & bin_centers_adj_gapless < movie_end_min_adj_gapless;
    phone_bins = bin_centers_adj_gapless >= phone_start_min_adj_gapless & bin_centers_adj_gapless < phone_end_min_adj_gapless;

    % Calculate the average counts and standard deviation for each condition
    movie_avg_count = mean(average_counts_gapless(movie_bins), 'omitnan');
    phone_avg_count = mean(average_counts_gapless(phone_bins), 'omitnan');

    movie_std_count = std(average_counts_gapless(movie_bins), 'omitnan');
    phone_std_count = std(average_counts_gapless(phone_bins), 'omitnan');

    %% Plot the average incidence of slow waves across selected channels %%

    figure;

    hold on;

    % Initialize arrays to store handles and labels
    legend_handles = [];
    legend_labels = {};

    %% 1. Plot the shaded areas first (background)
    % For Movie Condition
    if any(movie_bins)
        % Define upper and lower bounds
        movie_upper = movie_avg_count + movie_std_count;
        movie_lower = movie_avg_count - movie_std_count;
        % Time range for movie condition
        movie_time = [0, movie_end_min_adj_gapless];
        % Create shaded area
        patch([movie_time(1), movie_time(2), movie_time(2), movie_time(1)],...
              [movie_lower, movie_lower, movie_upper, movie_upper],...
              'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end

    % For Phone Condition
    if any(phone_bins)
        % Define upper and lower bounds
        phone_upper = phone_avg_count + phone_std_count;
        phone_lower = phone_avg_count - phone_std_count;
        % Time range for phone condition
        phone_time = [movie_end_min_adj_gapless, phone_end_min_adj_gapless];
        % Create shaded area
        patch([phone_time(1), phone_time(2), phone_time(2), phone_time(1)],...
              [phone_lower, phone_lower, phone_upper, phone_upper],...
              'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    end

    %% 2. Plot the average counts (data points)
    h_average_counts = plot(bin_centers_adj_gapless, average_counts_gapless, 'o-', 'LineWidth', 2, 'Color', [0.3 0.3 0.3]);
    % Add to legend
    legend_handles(end+1) = h_average_counts;
    legend_labels{end+1} = 'Average Counts';

    %% 3. Plot the average lines (foreground)
    % For Movie Condition
    if any(movie_bins)
        % Time range for movie condition
        movie_time = [0, movie_end_min_adj_gapless];
        % Plot average line
        h_movie_avg_line = plot([movie_time(1), movie_time(2)], [movie_avg_count, movie_avg_count], 'b--', 'LineWidth', 2);
        % Add to legend
        legend_handles(end+1) = h_movie_avg_line;
        legend_labels{end+1} = 'Movie Average ±1 SD';
    end

    % For Phone Condition
    if any(phone_bins)
        % Time range for phone condition
        phone_time = [movie_end_min_adj_gapless, phone_end_min_adj_gapless];
        % Plot average line
        h_phone_avg_line = plot([phone_time(1), phone_time(2)], [phone_avg_count, phone_avg_count], 'r--', 'LineWidth', 2);
        % Add to legend
        legend_handles(end+1) = h_phone_avg_line;
        legend_labels{end+1} = 'Phone Average ±1 SD';
    end

    %% 4. Plot vertical line at the end of the movie condition (topmost)
    h_xline = xline(movie_end_min_adj_gapless, 'Color', 'g', 'LineWidth', 2);
    legend_handles(end+1) = h_xline;
    legend_labels{end+1} = 'Movie End/Phone Start';

    %% Arrange legend entries in specified order
    % Desired order:
    % 1) Average Counts
    % 2) Movie End/Phone Start
    % 3) Movie Average ±1 SD
    % 4) Phone Average ±1 SD

    desired_order = {'Average Counts', 'Movie End/Phone Start', 'Movie Average ±1 SD', 'Phone Average ±1 SD'};

    [~, idx_order] = ismember(desired_order, legend_labels);
    valid_idx_order = idx_order > 0;
    idx_order = idx_order(valid_idx_order);
    ordered_handles = legend_handles(idx_order);
    ordered_labels = legend_labels(idx_order);

    legend(ordered_handles, ordered_labels, 'Location', 'best');

    %% Final plot adjustments
    xlabel('Time (minutes)');
    ylabel('Average Slow-Wave Count');
    title(sprintf('Average Slow-Wave Incidence per 1 Minute - %s', participant_id), 'Interpreter', 'none');
    grid on;

    %% Save the figure
    filename = fullfile(density_dir, sprintf('SWdensity_timeseries_%s.png', participant_id));
    saveas(gcf, filename);
    close(gcf); % Close the figure to prevent too many open figures

    %% Extract counts for movie and phone conditions
    counts_movie = average_counts_gapless(movie_bins);
    counts_phone = average_counts_gapless(phone_bins);
end