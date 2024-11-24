function [average_counts_movie, average_counts_phone] = density_binning(participant_id, participant_data, channels, density_dir)
% density_binning Computes and plots SW density/counts for a participant,
% binning separately for movie and phone conditions, and includes average lines and variability shading.

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
    movie_end_sec = movie_end / 1000;
    phone_start_sec = phone_start / 1000;
    phone_end_sec = phone_end / 1000;

    movie_length_sec = movie_end_sec - movie_start_sec;
    phone_length_sec = phone_end_sec - phone_start_sec;

    % Adjust channels data
    num_channels = length(top10_filtered_results.channels);
    for ch = 1:num_channels
        negzx = cell2mat(top10_filtered_results.channels(ch).negzx);
        idx_keep_movie_phone = (negzx >= movie_start & negzx < movie_end) | (negzx >= phone_start & negzx < phone_end);

        channel_fields = fieldnames(top10_filtered_results.channels(ch));
        for field_idx = 1:length(channel_fields)
            field = channel_fields{field_idx};
            if strcmp(field, 'datalength')
                top10_filtered_results.channels(ch).(field) = (movie_length_sec + phone_length_sec) * 1000; % Convert back to ms
            else
                field_data = top10_filtered_results.channels(ch).(field);
                top10_filtered_results.channels(ch).(field) = field_data(idx_keep_movie_phone);
            end
        end
    end

    %% PRINT PARTICIPANT INFO %%

    fprintf('\n---------------------------------------------\n');
    fprintf('Participant: %s\n\n', participant_id);
    fprintf('Movie start: %.1f min\n', movie_start_sec / 60);
    fprintf('Movie end: %.1f min\n', movie_end_sec / 60);
    fprintf('Phone start: %.1f min\n', phone_start_sec / 60);
    fprintf('Phone end: %.1f min\n\n', phone_end_sec / 60);
    fprintf('Movie length: %.1f min\n', movie_length_sec / 60);
    fprintf('Phone length: %.1f min\n\n', phone_length_sec / 60);
    fprintf('Recording end: %.1f min\n', recording_end / 1000 / 60);
    fprintf('---------------------------------------------\n\n');

    %% Binning for Movie Condition %%

    % Calculate number of full bins in movie condition
    num_full_bins_movie = floor(movie_length_sec / 60);

    if num_full_bins_movie >= 1
        % Define bin edges for movie condition
        bin_edges_movie_sec = movie_start_sec : 60 : (movie_start_sec + num_full_bins_movie * 60);
        num_bins_movie = length(bin_edges_movie_sec) - 1;
    else
        warning('Movie duration is less than one full bin for participant %s.', participant_id);
        average_counts_movie = [];
        num_bins_movie = 0;
    end

    % Initialize counts for movie condition
    channel_counts_movie = zeros(length(channels), num_bins_movie);

    % Binning for movie condition
    for ch_idx = 1:length(channels)
        ch = channels(ch_idx);
        maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;
        maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

        % Keep only data within movie condition
        maxnegpk_movie = maxnegpk_seconds(maxnegpk_seconds >= movie_start_sec & maxnegpk_seconds < movie_end_sec);

        % Count the occurrences in each bin for the current channel
        counts = histcounts(maxnegpk_movie, bin_edges_movie_sec);

        % Store counts for each channel
        channel_counts_movie(ch_idx, :) = counts;
    end

    % Average counts across channels for movie condition
    average_counts_movie = mean(channel_counts_movie, 1);

    %% Binning for Phone Condition %%

    % Calculate number of full bins in phone condition
    num_full_bins_phone = floor(phone_length_sec / 60);

    if num_full_bins_phone >= 1
        % Define bin edges for phone condition
        bin_edges_phone_sec = phone_start_sec : 60 : (phone_start_sec + num_full_bins_phone * 60);
        num_bins_phone = length(bin_edges_phone_sec) - 1;
    else
        warning('Phone duration is less than one full bin for participant %s.', participant_id);
        average_counts_phone = [];
        num_bins_phone = 0;
    end

    % Initialize counts for phone condition
    channel_counts_phone = zeros(length(channels), num_bins_phone);

    % Binning for phone condition
    for ch_idx = 1:length(channels)
        ch = channels(ch_idx);
        maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;
        maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

        % Keep only data within phone condition
        maxnegpk_phone = maxnegpk_seconds(maxnegpk_seconds >= phone_start_sec & maxnegpk_seconds < phone_end_sec);

        % Count the occurrences in each bin for the current channel
        counts = histcounts(maxnegpk_phone, bin_edges_phone_sec);

        % Store counts for each channel
        channel_counts_phone(ch_idx, :) = counts;
    end

    % Average counts across channels for phone condition
    average_counts_phone = mean(channel_counts_phone, 1);

    %% Calculate Standard Deviations Across Bins %%

    % Standard deviation across bins for movie condition
    std_counts_movie = std(average_counts_movie, 0, 'omitnan');

    % Standard deviation across bins for phone condition
    std_counts_phone = std(average_counts_phone, 0, 'omitnan');

    % Compute overall averages for each condition
    overall_avg_movie = mean(average_counts_movie, 'omitnan');
    overall_avg_phone = mean(average_counts_phone, 'omitnan');

    %% Combine Data for Plotting %%

    % Concatenate average counts
    average_counts_combined = [average_counts_movie, average_counts_phone];

    % Create x-axis based on bin indices (each bin represents 1 minute)
    total_bins = num_bins_movie + num_bins_phone;
    x_axis = 1:total_bins;

    %% Plotting %%

    figure;
    hold on;

    % --- Adjusted Plotting Order ---

    % 1. Add shaded areas representing ±1 SD around the average lines (plot first to be in the background)
    if num_bins_movie > 0
        % Shading for Movie condition (excluded from legend)
        x_movie = [0, num_bins_movie + 0.5, num_bins_movie + 0.5, 0];
        y_movie = [overall_avg_movie - std_counts_movie, overall_avg_movie - std_counts_movie, overall_avg_movie + std_counts_movie, overall_avg_movie + std_counts_movie];
        patch(x_movie, y_movie, 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    if num_bins_phone > 0
        % Shading for Phone condition (excluded from legend)
        x_phone = [num_bins_movie + 0.5, total_bins + 1, total_bins + 1, num_bins_movie + 0.5];
        y_phone = [overall_avg_phone - std_counts_phone, overall_avg_phone - std_counts_phone, overall_avg_phone + std_counts_phone, overall_avg_phone + std_counts_phone];
        patch(x_phone, y_phone, 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    % 2. Plot the average counts (data points)
    h_counts = plot(x_axis, average_counts_combined, 'o-', 'LineWidth', 2, 'Color', [0.3 0.3 0.3]);
    legend_handles = h_counts;
    legend_labels = {'Average Counts'};

    % 3. Add horizontal dashed lines representing overall averages
    if num_bins_movie > 0
        h_movie_avg = plot([0.5, num_bins_movie + 0.5], [overall_avg_movie, overall_avg_movie], 'b--', 'LineWidth', 2);
    end

    if num_bins_phone > 0
        h_phone_avg = plot([num_bins_movie + 0.5, total_bins + 0.5], [overall_avg_phone, overall_avg_phone], 'r--', 'LineWidth', 2);
    end

    % 4. Add vertical line to separate conditions (plot last to be on top)
    if num_bins_movie > 0 && num_bins_phone > 0
        h_boundary = xline(num_bins_movie + 0.5, 'Color', 'g', 'LineWidth', 2);
    end

    % --- End of Adjusted Plotting Order ---

    % Add horizontal average lines to legend
    if num_bins_movie > 0
        legend_handles(end+1) = h_movie_avg;
        legend_labels{end+1} = 'Movie Average ±1 SD';
    end

    if num_bins_phone > 0
        legend_handles(end+1) = h_phone_avg;
        legend_labels{end+1} = 'Phone Average ±1 SD';
    end

    % Add condition boundary line to legend
    if exist('h_boundary', 'var')
        legend_handles(end+1) = h_boundary;
        legend_labels{end+1} = 'Movie End/Phone Start';
    end

    % Adjust legend to desired order
    % Desired order:
    % 1) Average Counts
    % 2) Movie End/Phone Start
    % 3) Movie Average ±1 SD
    % 4) Phone Average ±1 SD

    % Reorder legend handles and labels accordingly
    % First, find indices of each item
    idx_counts = find(strcmp(legend_labels, 'Average Counts'));
    idx_boundary = find(strcmp(legend_labels, 'Movie End/Phone Start'));
    idx_movie_avg = find(strcmp(legend_labels, 'Movie Average ±1 SD'));
    idx_phone_avg = find(strcmp(legend_labels, 'Phone Average ±1 SD'));

    % Build legend_order array based on availability of handles
    legend_order = [];
    legend_order(end+1) = idx_counts;
    if ~isempty(idx_boundary)
        legend_order(end+1) = idx_boundary;
    end
    if ~isempty(idx_movie_avg)
        legend_order(end+1) = idx_movie_avg;
    end
    if ~isempty(idx_phone_avg)
        legend_order(end+1) = idx_phone_avg;
    end

    % Set the legend with the desired order
    legend(legend_handles(legend_order), legend_labels(legend_order), 'Location', 'best');

    % Labels and title
    xlabel('Time (minutes)');
    ylabel('Average Slow-Wave Count');
    title(sprintf('Average Slow-Wave Incidence per 1 Minute - %s', participant_id), 'Interpreter', 'none');
    grid on;

    %% Save the figure
    filename = fullfile(density_dir, sprintf('SWdensity_timeseries_%s.png', participant_id));
    saveas(gcf, filename);
    close(gcf); % Close the figure to prevent too many open figures
end