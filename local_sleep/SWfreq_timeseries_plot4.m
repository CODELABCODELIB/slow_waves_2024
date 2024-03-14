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

right_channels = [64, 35, 50, 36, 20, 21, 8, 37, 51, 9, 22, 2, 10, 38, ...
                 23, 3, 11, 52, 24, 39, 12, 25, 26, 40, 53, 41, 54, 62];
left_channels = [63, 49, 60, 48, 33, 32, 18, 47, 59, 31, 17, 6, 46, 16, ...
                  30, 5, 15, 58, 45, 29, 14, 28, 44, 27, 57, 43, 61, 56];

SW_counts_r = [];
SW_counts_l = [];

for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(right_channels)
        current_channel = right_channels(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_r(bin) = mean(bin_counts);
end
    
for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(left_channels)
        current_channel = left_channels(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_l(bin) = mean(bin_counts);
end

%%

% Plot the unsmoothed time series
figure;
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, SW_counts_r, 'o-r', 'LineWidth', 2);
hold on;
plot(bin_centers / 60, SW_counts_l, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Slow-Wave Count');
title('Unsmoothed Slow-Wave Frequency per 5 Minutes - Right vs. Left Channels');
legend('Right', 'Left', 'Location', 'northeast');
grid on;
hold off;

%%

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
SW_counts_r_sm = movmean(SW_counts_r, window_size);
SW_counts_l_sm = movmean(SW_counts_l, window_size);

%%

% Plot the smoothed time series in a new figure
figure;
plot(bin_centers / 60, SW_counts_r_sm, 'o-r', 'LineWidth', 2);
hold on;
plot(bin_centers / 60, SW_counts_l_sm, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Slow-Wave Count (Smoothed)');
title('Smoothed Slow-Wave Frequency per 5 Minutes - Right vs. Left Channels');
legend('Right', 'Left', 'Location', 'northeast');
grid on;
hold off;
