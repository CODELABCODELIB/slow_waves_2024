% Load processed and filtered data
load('top10_filtered_results.mat');

%%

% Define bin edges (5-minute bins in seconds)
recording_duration_seconds = top10_filtered_results.channels(1).datalength / 128; % 128 = fs of downsampled EEG data
bin_edges = 0:300:recording_duration_seconds; % 300 seconds = 5 minutes

%%

% Select channels

selected_ch1 = [4, 5, 6, 10, 11, 12, 13, 14, 15, 16, 24, 25, ...
                26, 27, 28, 29, 41, 42, 43, 44, 45, 54, 55, 56]; % High density, low p2p-amplitude
selected_ch2 = [19, 20, 21, 22, 23, 30, 31, 32, 33, 34, 35, 36, ...
                37, 38, 39, 46, 47, 48, 49, 50, 59, 60, 63, 64]; % Low density, high p2p-amplitude

% selected_ch1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, ...
%                 17, 18, 24, 25, 26, 27, 28, 29, 41, 42, 43, 44, 45, 54, 55, 56]; % High density
% selected_ch2 = [1, 2, 3, 7, 8, 9, 17, 18, 19, 20, 21, 22, 23, 30, 31, 32, ...
%                 33, 34, 35, 36, 37, 38, 39, 46, 47, 48, 49, 50, 59, 60, 63, 64]; % High p2p-amplitude

%%

% Initialize struct array for the slow-wave counts
SW_counts = struct();

% Initialize cell array for the different channels
SW_counts.channels = cell(length(top10_filtered_results.channels), 1);

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

% Initialize arrays to hold the slow-wave bin counts
SW_counts_1 = [];
SW_counts_2 = [];

% Calculate the average slow-wave counts for 'selected_ch1'
for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(selected_ch1)
        current_channel = selected_ch1(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_1(bin) = mean(bin_counts);
end

% Calculate the average slow-wave counts for 'selected_ch2'
for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch_idx = 1:length(selected_ch2)
        current_channel = selected_ch2(ch_idx);
        bin_counts(ch_idx) = SW_counts.channels{current_channel}(bin);
    end
    SW_counts_2(bin) = mean(bin_counts);
end

%%

% Extract all peak-to-peak amplitudes for each channel
p2pamp = arrayfun(@(x) abs(cell2mat(x.maxnegpkamp)) + cell2mat(x.maxpospkamp), top10_filtered_results.channels, 'UniformOutput', false);

% Initialize struct array for the average peak-to-peak amplitudes
SW_avg_p2p_amp = struct();

% Initialize cell array for the different channels
SW_avg_p2p_amp.channels = cell(length(top10_filtered_results.channels), 1);

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

% Initialize arrays to hold the peak-to-peak amplitude bin averages
avg_p2p_amp_1 = [];
avg_p2p_amp_2 = [];

% Calculate the average peak-to-peak amplitudes for 'selected_ch1'
for bin = 1:length(SW_avg_p2p_amp.channels{1})
    bin_amplitudes = [];
    for ch_idx = 1:length(selected_ch1)
        current_channel = selected_ch1(ch_idx);
        bin_amplitudes(ch_idx) = SW_avg_p2p_amp.channels{current_channel}(bin);
    end
    avg_p2p_amp_1(bin) = mean(bin_amplitudes, 'omitnan');
end

% Calculate the average peak-to-peak amplitudes for 'selected_ch2'
for bin = 1:length(SW_avg_p2p_amp.channels{1})
    bin_amplitudes = [];
    for ch_idx = 1:length(selected_ch2)
        current_channel = selected_ch2(ch_idx);
        bin_amplitudes(ch_idx) = SW_avg_p2p_amp.channels{current_channel}(bin);
    end
    avg_p2p_amp_2(bin) = mean(bin_amplitudes, 'omitnan');
end

%%

% Plot the unsmoothed time series with two different y-axes
figure;
yyaxis left; % Activate left y-axis for slow-wave frequencies
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, SW_counts_1, 'o-', 'LineWidth', 2, 'Color', '#0072BD', 'MarkerFaceColor', '#0072BD');
hold on;
plot(bin_centers / 60, SW_counts_2, 'o--', 'LineWidth', 2, 'Color', '#4DBEEE', 'MarkerFaceColor', 'white');
ylabel('Count');
xlabel('Time (minutes)');
title('Unsmoothed SW Freq. & P2P-Amp. per 5 Min – HighDens./LowP2P-Amp. vs. LowDens./HighP2P-Amp.');
% title('Unsmoothed SW Freq. & P2P-Amp. per 5 Min – High Density vs. High P2P-Amp.');
grid on;
hold off;

yyaxis right; % Activate right y-axis for slow-wave peak-to-peak amplitudes
plot(bin_centers / 60, avg_p2p_amp_1, 'o-', 'LineWidth', 2, 'Color', '#A2142F', 'MarkerFaceColor', '#A2142F');
hold on;
plot(bin_centers / 60, avg_p2p_amp_2, 'o--', 'LineWidth', 2, 'Color', '#D95319', 'MarkerFaceColor', 'white');
ylabel('Peak-To-Peak Amplitude (μV)');
hold off;

% Adjusting legend to include both time series
lg = legend('SW Freq: HighD/LowP2P', 'SW Freq: LowD/HighP2P', 'SW P2P: HighD/LowP2P', 'SW P2P: LowD/HighP2P');
% lg = legend('SW Freq: High Density', 'SW Freq: High P2P-Amp.', 'SW P2P: High Density', 'SW P2P: High P2P-Amp.');
set(lg, 'FontSize', 10);

%%

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
SW_counts_1_sm = movmean(SW_counts_1, window_size);
SW_counts_2_sm = movmean(SW_counts_2, window_size);
avg_p2p_amp_1_sm = movmean(avg_p2p_amp_1, window_size);
avg_p2p_amp_2_sm = movmean(avg_p2p_amp_2, window_size);

%%

% Plot the smoothed time series with two different y-axes
figure;
yyaxis left; % Activate left y-axis for slow-wave frequencies
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, SW_counts_1_sm, 'o-', 'LineWidth', 2, 'Color', '#0072BD', 'MarkerFaceColor', '#0072BD');
hold on;
plot(bin_centers / 60, SW_counts_2_sm, 'o--', 'LineWidth', 2, 'Color', '#4DBEEE', 'MarkerFaceColor', 'white');
ylabel('Count (Smoothed)');
xlabel('Time (minutes)');
title('Smoothed SW Freq. & P2P-Amp. per 5 Min – HighDens./LowP2P-Amp. vs. LowDens./HighP2P-Amp.');
% title('Smoothed SW Freq. & P2P-Amp. per 5 Min – High Density vs. High P2P-Amp.');
grid on;
hold off;

yyaxis right; % Activate right y-axis for slow-wave peak-to-peak amplitudes
plot(bin_centers / 60, avg_p2p_amp_1_sm, 'o-', 'LineWidth', 2, 'Color', '#A2142F', 'MarkerFaceColor', '#A2142F');
hold on;
plot(bin_centers / 60, avg_p2p_amp_2_sm, 'o--', 'LineWidth', 2, 'Color', '#D95319', 'MarkerFaceColor', 'white');
ylabel('Peak-To-Peak Amplitude (Smoothed; μV)');
hold off;

% Adjusting legend to include both time series
lg = legend('SW Freq: HighD/LowP2P', 'SW Freq: LowD/HighP2P', 'SW P2P: HighD/LowP2P', 'SW P2P: LowD/HighP2P');
% lg = legend('SW Freq: High Density', 'SW Freq: High P2P-Amp.', 'SW P2P: High Density', 'SW P2P: High P2P-Amp.');
set(lg, 'FontSize', 10);