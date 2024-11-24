function [median_amplitudes_movie, median_amplitudes_phone] = amplitude_binning(participant_id, participant_data, channels, amplitude_dir)
% amplitude_binning Computes and plots SW amplitude for a participant,
% binning separately for movie and phone conditions, and includes mean lines and variability shading.

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

    % Convert times to seconds
    movie_start_sec = movie_start / 1000;
    movie_end_sec = movie_end / 1000;
    phone_start_sec = phone_start / 1000;
    phone_end_sec = phone_end / 1000;

    % Calculate lengths
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
        median_amplitudes_movie = [];
        num_bins_movie = 0;
    end

    % Initialize cell array to store amplitudes per bin
    bin_amplitudes_movie = cell(1, num_bins_movie);

    % Binning for movie condition
    for ch = channels
        maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;
        maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

        % Extract amplitudes
        maxnegpkamp_data = top10_filtered_results.channels(ch).maxnegpkamp;
        maxpospkamp_data = top10_filtered_results.channels(ch).maxpospkamp;
        maxnegpkamp_values = cell2mat(maxnegpkamp_data);
        maxpospkamp_values = cell2mat(maxpospkamp_data);
        amplitudes = abs(maxnegpkamp_values) + maxpospkamp_values;

        % Keep only data within movie condition
        idx_movie = maxnegpk_seconds >= movie_start_sec & maxnegpk_seconds < movie_end_sec;
        maxnegpk_movie = maxnegpk_seconds(idx_movie);
        amplitudes_movie = amplitudes(idx_movie);

        % Assign amplitudes to bins
        [~, ~, bin_indices] = histcounts(maxnegpk_movie, bin_edges_movie_sec);
        for i = 1:length(bin_indices)
            bin_idx = bin_indices(i);
            if bin_idx >= 1 && bin_idx <= num_bins_movie
                bin_amplitudes_movie{bin_idx} = [bin_amplitudes_movie{bin_idx}, amplitudes_movie(i)];
            end
        end
    end

    % Compute median amplitude per bin for movie condition
    median_amplitudes_movie = zeros(1, num_bins_movie);
    for bin_idx = 1:num_bins_movie
        if ~isempty(bin_amplitudes_movie{bin_idx})
            median_amplitudes_movie(bin_idx) = median(bin_amplitudes_movie{bin_idx});
        else
            median_amplitudes_movie(bin_idx) = NaN;
        end
    end

    %% Binning for Phone Condition %%

    % Calculate number of full bins in phone condition
    num_full_bins_phone = floor(phone_length_sec / 60);

    if num_full_bins_phone >= 1
        % Define bin edges for phone condition
        bin_edges_phone_sec = phone_start_sec : 60 : (phone_start_sec + num_full_bins_phone * 60);
        num_bins_phone = length(bin_edges_phone_sec) - 1;
    else
        warning('Phone duration is less than one full bin for participant %s.', participant_id);
        median_amplitudes_phone = [];
        num_bins_phone = 0;
    end

    % Initialize cell array to store amplitudes per bin
    bin_amplitudes_phone = cell(1, num_bins_phone);

    % Binning for phone condition
    for ch = channels
        maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;
        maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

        % Extract amplitudes
        maxnegpkamp_data = top10_filtered_results.channels(ch).maxnegpkamp;
        maxpospkamp_data = top10_filtered_results.channels(ch).maxpospkamp;
        maxnegpkamp_values = cell2mat(maxnegpkamp_data);
        maxpospkamp_values = cell2mat(maxpospkamp_data);
        amplitudes = abs(maxnegpkamp_values) + maxpospkamp_values;

        % Keep only data within phone condition
        idx_phone = maxnegpk_seconds >= phone_start_sec & maxnegpk_seconds < phone_end_sec;
        maxnegpk_phone = maxnegpk_seconds(idx_phone);
        amplitudes_phone = amplitudes(idx_phone);

        % Assign amplitudes to bins
        [~, ~, bin_indices] = histcounts(maxnegpk_phone, bin_edges_phone_sec);
        for i = 1:length(bin_indices)
            bin_idx = bin_indices(i);
            if bin_idx >= 1 && bin_idx <= num_bins_phone
                bin_amplitudes_phone{bin_idx} = [bin_amplitudes_phone{bin_idx}, amplitudes_phone(i)];
            end
        end
    end

    % Compute median amplitude per bin for phone condition
    median_amplitudes_phone = zeros(1, num_bins_phone);
    for bin_idx = 1:num_bins_phone
        if ~isempty(bin_amplitudes_phone{bin_idx})
            median_amplitudes_phone(bin_idx) = median(bin_amplitudes_phone{bin_idx});
        else
            median_amplitudes_phone(bin_idx) = NaN;
        end
    end

    %% Calculate Mean and Standard Deviations Across Bins %%

    % Compute mean of median amplitudes across bins for each condition
    mean_of_medians_movie = mean(median_amplitudes_movie, 'omitnan');
    mean_of_medians_phone = mean(median_amplitudes_phone, 'omitnan');

    % Compute standard deviation of median amplitudes across bins for each condition
    std_of_medians_movie = std(median_amplitudes_movie, 0, 'omitnan');
    std_of_medians_phone = std(median_amplitudes_phone, 0, 'omitnan');

    %% Combine Data for Plotting %%

    % Concatenate median amplitudes
    median_amplitudes_combined = [median_amplitudes_movie, median_amplitudes_phone];

    % Create x-axis based on bin indices (each bin represents 1 minute)
    total_bins = num_bins_movie + num_bins_phone;
    x_axis = 1:total_bins;

    %% Plotting %%

    figure;
    hold on;

    % --- Adjusted Plotting Order ---

    % 1. Add shaded areas representing ±1 SD around the mean lines (plot first to be in the background)
    if num_bins_movie > 0
        % Shading for Movie condition (excluded from legend)
        x_movie = [0, num_bins_movie + 0.5, num_bins_movie + 0.5, 0];
        y_movie = [mean_of_medians_movie - std_of_medians_movie, mean_of_medians_movie - std_of_medians_movie, mean_of_medians_movie + std_of_medians_movie, mean_of_medians_movie + std_of_medians_movie];
        patch(x_movie, y_movie, 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    if num_bins_phone > 0
        % Shading for Phone condition (excluded from legend)
        x_phone = [num_bins_movie + 0.5, total_bins + 1, total_bins + 1, num_bins_movie + 0.5];
        y_phone = [mean_of_medians_phone - std_of_medians_phone, mean_of_medians_phone - std_of_medians_phone, mean_of_medians_phone + std_of_medians_phone, mean_of_medians_phone + std_of_medians_phone];
        patch(x_phone, y_phone, 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end

    % 2. Plot the median amplitudes (data points)
    valid_idx = ~isnan(median_amplitudes_combined);
    x_valid = x_axis(valid_idx);
    y_valid = median_amplitudes_combined(valid_idx);

    h_median = plot(x_valid, y_valid, 'o-', 'LineWidth', 2, 'Color', [0.3 0.3 0.3]);
    legend_handles = h_median;
    legend_labels = {'Median Amplitudes'};

    % 3. Indicate missing data with red crosses
    missing_idx = isnan(median_amplitudes_combined);
    if any(missing_idx)
        h_missing = plot(x_axis(missing_idx), zeros(sum(missing_idx),1), 'rx', 'LineWidth', 2);
        legend_handles(end+1) = h_missing;
        legend_labels{end+1} = 'No Slow Waves Detected';
    end

    % 4. Add horizontal dashed lines representing mean of medians
    if num_bins_movie > 0
        h_movie_mean = plot([0.5, num_bins_movie + 0.5], [mean_of_medians_movie, mean_of_medians_movie], 'b--', 'LineWidth', 2);
    end

    if num_bins_phone > 0
        h_phone_mean = plot([num_bins_movie + 0.5, total_bins + 0.5], [mean_of_medians_phone, mean_of_medians_phone], 'r--', 'LineWidth', 2);
    end

    % 5. Add vertical line to separate conditions (plot last to be on top)
    if num_bins_movie > 0 && num_bins_phone > 0
        h_boundary = xline(num_bins_movie + 0.5, 'Color', 'g', 'LineWidth', 2);
    end

    % --- End of Adjusted Plotting Order ---

    % Add horizontal average lines to legend
    if num_bins_movie > 0
        legend_handles(end+1) = h_movie_mean;
        legend_labels{end+1} = 'Movie Average ±1 SD';
    end

    if num_bins_phone > 0
        legend_handles(end+1) = h_phone_mean;
        legend_labels{end+1} = 'Phone Average ±1 SD';
    end

    % Add condition boundary line to legend
    if exist('h_boundary', 'var')
        legend_handles(end+1) = h_boundary;
        legend_labels{end+1} = 'Movie End/Phone Start';
    end

    % Adjust legend to desired order
    % Desired order:
    % 1) Median Amplitudes
    % 2) No Slow Waves Detected
    % 3) Movie End/Phone Start
    % 4) Movie Average ±1 SD
    % 5) Phone Average ±1 SD

    % Reorder legend handles and labels accordingly
    % First, find indices of each item
    idx_median = find(strcmp(legend_labels, 'Median Amplitudes'));
    idx_missing = find(strcmp(legend_labels, 'No Slow Waves Detected'));
    idx_boundary = find(strcmp(legend_labels, 'Movie End/Phone Start'));
    idx_movie_avg = find(strcmp(legend_labels, 'Movie Average ±1 SD'));
    idx_phone_avg = find(strcmp(legend_labels, 'Phone Average ±1 SD'));

    % Build legend_order array based on availability of handles
    legend_order = [];
    legend_order(end+1) = idx_median;
    if ~isempty(idx_missing)
        legend_order(end+1) = idx_missing;
    end
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
    ylabel('Median Slow-Wave Amplitude (\muV)');
    title(sprintf('Median Slow-Wave Amplitude per 1 Minute - %s', participant_id), 'Interpreter', 'none');
    grid on;

    %% Save the figure
    filename = fullfile(amplitude_dir, sprintf('SWamplitude_timeseries_%s.png', participant_id));
    saveas(gcf, filename);
    close(gcf); % Close the figure to prevent too many open figures
end