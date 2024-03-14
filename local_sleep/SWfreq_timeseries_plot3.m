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

central_channels = 1:33;
peripheral_channels = 34:length(top10_filtered_results.channels);

SW_counts_cen = [];
SW_counts_per = [];

for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(central_channels)
        current_channel = central_channels(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_cen(bin) = mean(bin_counts);
end
    
for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(peripheral_channels)
        current_channel = peripheral_channels(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_per(bin) = mean(bin_counts);
end

%%

% Plot the unsmoothed time series
figure;
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, SW_counts_cen, 'o-r', 'LineWidth', 2);
hold on;
plot(bin_centers / 60, SW_counts_per, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Slow-Wave Count');
title('Unsmoothed Slow-Wave Frequency per 5 Minutes - Central vs. Peripheral Channels');
legend('Central', 'Peripheral', 'Location', 'northeast');
grid on;
hold off;

%%

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
SW_counts_cen_sm = movmean(SW_counts_cen, window_size);
SW_counts_per_sm = movmean(SW_counts_per, window_size);

%%

% Plot the smoothed time series in a new figure
figure;
plot(bin_centers / 60, SW_counts_cen_sm, 'o-r', 'LineWidth', 2);
hold on;
plot(bin_centers / 60, SW_counts_per_sm, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Slow-Wave Count (Smoothed)');
title('Smoothed Slow-Wave Frequency per 5 Minutes - Central vs. Peripheral Channels');
legend('Central', 'Peripheral', 'Location', 'northeast');
grid on;
hold off;
