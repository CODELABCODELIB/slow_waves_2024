% Load the data
load('top10_filtered_results.mat');

%%

% Select channel
channel_number = 1;

% Extract 'maxnegpk' (positions of negative peaks in ms of recording duration) for the specified channel
maxnegpk_data = top10_filtered_results.channels(channel_number).maxnegpk;

% Convert 'maxnegpk' data into seconds
maxnegpk_seconds = cell2mat(maxnegpk_data) / 1000;

% Define bin edges (5-minute bins in seconds)
recording_duration_seconds = top10_filtered_results.channels(channel_number).datalength / 128;
bin_edges = 0:300:recording_duration_seconds; % 300 seconds = 5 minutes

% Count the occurrences in each bin
[counts, ~] = histcounts(maxnegpk_seconds, bin_edges);

% Plot the unsmoothed time series
figure;
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, counts, 'o-', 'LineWidth', 2); % Convert bin centers to minutes for the x-axis
xlabel('Time (minutes)');
ylabel('Slow-Wave Count');
title(sprintf('Unsmoothed Slow-Wave Frequency per 5 Minutes - Channel %d', channel_number));
grid on;

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
smoothed_counts = movmean(counts, window_size);

% Plot the smoothed time series in a new figure
figure;
plot(bin_centers / 60, smoothed_counts, 'o-', 'LineWidth', 2); % Use smoothed_counts here
xlabel('Time (minutes)');
ylabel('Slow-Wave Count (Smoothed)');
title(sprintf('Smoothed Slow-Wave Frequency per 5 Minutes - Channel %d', channel_number));
grid on;
