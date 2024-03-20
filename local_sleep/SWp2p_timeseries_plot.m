% Load the data
load('top10_filtered_results.mat');

%%

% Extract all peak-to-peak amplitudes for each channel
p2pamp = arrayfun(@(x) abs(cell2mat(x.maxnegpkamp)) + cell2mat(x.maxpospkamp), top10_filtered_results.channels, 'UniformOutput', false);

%%

% Initialize struct array for the average peak-to-peak amplitudes
SW_avg_p2p_amp = struct();

% Initialize cell array for the different channels
SW_avg_p2p_amp.channels = cell(length(top10_filtered_results.channels), 1);

% Define bin edges (5-minute bins in seconds)
recording_duration_seconds = top10_filtered_results.channels(1).datalength / 128; % 128 = fs of downsampled EEG data
bin_edges = 0:300:recording_duration_seconds; % 300 seconds = 5 minutes

% Loop through channels
for ch = 1:length(top10_filtered_results.channels)
    % Extract 'negzx' (start times of the waves in ms of recording duration) for the specified channel
    wave_starts_ms = top10_filtered_results.channels(ch).negzx;
    % Retrieve all peak-to-peak amplitudes for the specified channel from 'p2pamp'
    wave_p2p_amps = p2pamp{ch};
    
    % Initialize array to hold the sum of amplitudes for each bin
    bin_p2p_sums = zeros(length(bin_edges)-1, 1);

    % Initialize array to hold the wave counts for each bin
    bin_wave_counts = zeros(length(bin_edges)-1, 1);
    
    % Convert 'wave_starts_ms' into seconds
    wave_starts_seconds = cell2mat(wave_starts_ms) / 1000;
    
    % Loop through each bin edge to sum and average amplitudes
    for bin = 1:length(bin_edges)-1
        in_bin = wave_starts_seconds >= bin_edges(bin) & wave_starts_seconds < bin_edges(bin + 1);
        bin_p2p_sums(bin) = sum(wave_p2p_amps(in_bin));
        bin_wave_counts(bin) = sum(in_bin);
    end
    
    % Calculate average p2p amplitude per bin, avoiding division by zero
    bin_avg_p2p = bin_p2p_sums ./ bin_wave_counts;
    bin_avg_p2p(bin_wave_counts == 0) = NaN; % Use NaN for bins with no waves to avoid division by zero errors
    
    % Assign the average p2p amplitudes to a cell corresponding to the current channel
    SW_avg_p2p_amp.channels{ch} = bin_avg_p2p;
end

%%

% Define channel groups

channels_group1 = 1:64; % All channels

% channels_group1 = X; % Channel X

% channels_group1 = [63, 64, 34, 49, 35, 60, 50, 48, 19, 36, 33, 20, 32, 7, 21, 47, ... % Anterior channels
%                    18, 8, 37, 59, 51, 31, 17, 1, 9, 22, 6, 2, 46, 16, 10, 38];
% channels_group2 = setdiff(1:length(top10_filtered_results.channels), channels_group1); % Posterior channels

% channels_group1 = 1:33; % Central channels
% channels_group2 = 34:length(top10_filtered_results.channels); % Peripheral channels

% channels_group1 = [64, 35, 50, 36, 20, 21, 8, 37, 51, 9, 22, 2, 10, 38, ... % Right channels
%                    23, 3, 11, 52, 24, 39, 12, 25, 26, 40, 53, 41, 54, 62];
% channels_group2 = [63, 49, 60, 48, 33, 32, 18, 47, 59, 31, 17, 6, 46, 16, ... % Left channels
%                    30, 5, 15, 58, 45, 29, 14, 28, 44, 27, 57, 43, 61, 56];

% Initialize arrays to hold the peak-to-peak amplitude bin averages for the channel groups
avg_p2p_amp_grp1 = [];
avg_p2p_amp_grp2 = [];

%%

% Calculate the average peak-to-peak amplitude for channel group 1
for bin = 1:length(SW_avg_p2p_amp.channels{1})
    bin_amplitudes = [];
    for ch_idx = 1:length(channels_group1)
        current_channel = channels_group1(ch_idx);
        bin_amplitudes(ch_idx) = SW_avg_p2p_amp.channels{current_channel}(bin);
    end
    avg_p2p_amp_grp1(bin) = mean(bin_amplitudes, 'omitnan');
end

%% Run this section only when using 2 groups
    
% Calculate the average peak-to-peak amplitude for channel group 2
for bin = 1:length(SW_avg_p2p_amp.channels{1})
    bin_amplitudes = [];
    for ch_idx = 1:length(channels_group2)
        current_channel = channels_group2(ch_idx);
        bin_amplitudes(ch_idx) = SW_avg_p2p_amp.channels{current_channel}(bin);
    end
    avg_p2p_amp_grp2(bin) = mean(bin_amplitudes, 'omitnan');
end

%%

% Plot the unsmoothed time series
figure;
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, avg_p2p_amp_grp1, 'o-', 'LineWidth', 2); % Use for averaging over all channels / a single channel
% plot(bin_centers / 60, avg_p2p_amp_grp1, 'o-r', 'LineWidth', 2);
hold on;
% plot(bin_centers / 60, avg_p2p_amp_grp2, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Peak-To-Peak Amplitude (μV)');
title('Unsmoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - All Channels');
% title('Unsmoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Channel X');
% title('Unsmoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Anterior vs. Posterior Channels');
% title('Unsmoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Central vs. Peripheral Channels');
% title('Unsmoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Right vs. Left Channels');
% legend('Anterior', 'Posterior', 'Location', 'northeast');
% legend('Central', 'Peripheral', 'Location', 'northeast');
% legend('Right', 'Left', 'Location', 'northeast');
grid on;
hold off;

%%

% Calculate the moving average for the peak-to-peak amplitudes with a specified window size
window_size = 5; % Size of the moving window
avg_p2p_amp_grp1_sm = movmean(avg_p2p_amp_grp1, window_size);
avg_p2p_amp_grp2_sm = movmean(avg_p2p_amp_grp2, window_size);

%%

% Plot the smoothed time series in a new figure
figure;
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, avg_p2p_amp_grp1_sm, 'o-', 'LineWidth', 2); % Use for averaging over all channels / a single channel
% plot(bin_centers / 60, avg_p2p_amp_grp1_sm, 'o-r', 'LineWidth', 2);
hold on;
% plot(bin_centers / 60, avg_p2p_amp_grp2_sm, 'o-b', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Peak-To-Peak Amplitude (Smoothed; μV)');
title('Smoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - All Channels');
% title('Smoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Channel X');
% title('Smoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Anterior vs. Posterior Channels');
% title('Smoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Central vs. Peripheral Channels');
% title('Smoothed Slow-Wave Peak-To-Peak Amplitude per 5 Minutes - Right vs. Left Channels');
% legend('Anterior', 'Posterior', 'Location', 'northeast');
% legend('Central', 'Peripheral', 'Location', 'northeast');
% legend('Right', 'Left', 'Location', 'northeast');
grid on;
hold off;