% Load the data
load('top10_filtered_results.mat');

%%

% Initialize struct array for the slow-wave counts
SW_counts = struct();

% Initialize cell array for the different channels
SW_counts.channels = cell(length(top10_filtered_results.channels), 1);

% Define bin edges (5-minute bins in seconds)
recording_duration_seconds = top10_filtered_results.channels(1).datalength / 128; % 128 = fs of downsampled EEG data
bin_edges = 0:300:recording_duration_seconds; % 300 seconds = 5 minutes

% Loop through channels
for ch = 1:length(top10_filtered_results.channels)

    % Extract 'maxnegpk' (positions of negative peaks in ms of recording duration) for the specified channel
    maxnegpk_data = top10_filtered_results.channels(ch).maxnegpk;
    
    % Convert 'maxnegpk' data into seconds
    maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;
    
    % Count the occurrences in each bin
    [counts, ~] = histcounts(maxnegpk_seconds, bin_edges);

    % Assign the bin counts to a cell corresponding to the current channel
    SW_counts.channels{ch} = counts;

end

%%

anterior_channels = [63, 64, 34, 49, 35, 60, 50, 48, 19, 36, 33, 20, 32, 7, 21, 47, ...
                     18, 8, 37, 59, 51, 31, 17, 1, 9, 22, 6, 2, 46, 16, 10, 38];
posterior_channels = setdiff(1:length(top10_filtered_results.channels), anterior_channels);

SW_counts_ant = [];
SW_counts_post = [];

for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(anterior_channels)
        current_channel = anterior_channels(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_ant(bin) = mean(bin_counts);
end
    
for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(posterior_channels)
        current_channel = posterior_channels(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_post(bin) = mean(bin_counts);
end

%%

% Plot the unsmoothed time series
figure;
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, SW_counts_ant, 'o-r', 'LineWidth', 2);
hold on;
plot(bin_centers / 60, SW_counts_post, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Slow-Wave Count');
title('Unsmoothed Slow-Wave Frequency per 5 Minutes - Anterior vs. Posterior Channels');
legend('Anterior', 'Posterior', 'Location', 'northeast');
grid on;
hold off;

%%

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
SW_counts_ant_sm = movmean(SW_counts_ant, window_size);
SW_counts_post_sm = movmean(SW_counts_post, window_size);

%%

% Plot the smoothed time series in a new figure
figure;
plot(bin_centers / 60, SW_counts_ant_sm, 'o-r', 'LineWidth', 2);
hold on;
plot(bin_centers / 60, SW_counts_post_sm, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Slow-Wave Count (Smoothed)');
title('Smoothed Slow-Wave Frequency per 5 Minutes - Anterior vs. Posterior Channels');
legend('Anterior', 'Posterior', 'Location', 'northeast');
grid on;
hold off;
