% Load processed and filtered data
load('top10_filtered_results.mat');

%%

% Define bin edges (5-minute bins in seconds)
recording_duration_seconds = top10_filtered_results.channels(1).datalength / 128; % 128 = fs of downsampled EEG data
bin_edges = 0:300:recording_duration_seconds; % 300 seconds = 5 minutes

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

for bin = 1:length(SW_counts.channels{1})
    bin_counts = [];
    for ch = 1:length(top10_filtered_results.channels)
        bin_counts(ch) = SW_counts.channels{ch}(bin);
    end
    SW_counts_allCH(bin) = mean(bin_counts);
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

% Initialize array to hold the peak-to-peak amplitude bin averages across all channels
avg_p2p_amp_allCH = [];

% Calculate the average peak-to-peak amplitude for channel group 1
for bin = 1:length(SW_avg_p2p_amp.channels{1})
    bin_amplitudes = [];
    for ch = 1:length(top10_filtered_results.channels)
        bin_amplitudes(ch) = SW_avg_p2p_amp.channels{ch}(bin);
    end
    avg_p2p_amp_allCH(bin) = mean(bin_amplitudes, 'omitnan');
end

%%

% Plot the unsmoothed time series with two different y-axes
figure;
yyaxis left; % Activate left y-axis for slow-wave frequencies
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, SW_counts_allCH, 'o-', 'LineWidth', 2, 'Color', 'blue');
ylabel('Count');
xlabel('Time (minutes)');
title('Unsmoothed Slow-Wave Frequency and Peak-To-Peak Amplitude per 5 Minutes');
grid on;

yyaxis right; % Activate right y-axis for slow-wave peak-to-peak amplitudes
plot(bin_centers / 60, avg_p2p_amp_allCH, 'o-', 'LineWidth', 2, 'Color', 'red');
ylabel('Peak-To-Peak Amplitude (μV)');

% Adjusting legend to include both time series
legend('SW Frequency', 'SW P2P Amplitude');

%%

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
SW_counts_allCH_sm = movmean(SW_counts_allCH, window_size);
avg_p2p_amp_allCH_sm = movmean(avg_p2p_amp_allCH, window_size);

%%

% Plot the smoothed time series in a new figure with two y-axes
figure;
yyaxis left; % Activate left y-axis for smoothed slow-wave frequencies
plot(bin_centers / 60, SW_counts_allCH_sm, 'o-', 'LineWidth', 2, 'Color', 'blue');
ylabel('Count (Smoothed)');
xlabel('Time (minutes)');
title('Smoothed Slow-Wave Frequency and Peak-To-Peak Amplitude per 5 Minutes');
grid on;

yyaxis right; % Activate left y-axis for smoothed peak-to-peak amplitudes
plot(bin_centers / 60, avg_p2p_amp_allCH_sm, 'o-', 'LineWidth', 2, 'Color', 'red');
ylabel('Peak-To-Peak Amplitude (Smoothed; μV)');

% Adjusting legend to include both smoothed time series
legend('SW Frequency', 'SW P2P Amplitude');