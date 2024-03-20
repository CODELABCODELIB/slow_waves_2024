% load processed and filtered data
load('top10_filtered_results.mat');

%%
eeglab nogui;

% load original EEG data
EEG = pop_loadset('filename', '12_57_07_05_18.set', 'filepath', '/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/AT08');

%%

% Extract all peak-to-peak amplitudes for each channel
p2pamp = arrayfun(@(x) abs(cell2mat(x.maxnegpkamp)) + cell2mat(x.maxpospkamp), top10_filtered_results.channels, 'UniformOutput', false);

% Extract blink times
blinks_t = unique([EEG.icaquant{1, 1}.artifactlatencies, EEG.icaquant{1, 2}.artifactlatencies]);

%%

% Define bin edges (5-minute bins in seconds)
recording_duration_seconds = top10_filtered_results.channels(1).datalength / 128; % 128 = fs of downsampled EEG data
bin_edges = 0:300:recording_duration_seconds; % 300 seconds = 5 minutes

%%

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

% Convert 'blinks_t' into seconds
blinks_t_sec = blinks_t / 1000;
    
% Count the slow-wave/blink occurrences in each bin
[BL_counts, ~] = histcounts(blinks_t_sec, bin_edges);

%%

% Plot the unsmoothed time series with two different y-axes
figure;
yyaxis left; % Activate left y-axis for peak-to-peak amplitudes
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, avg_p2p_amp_allCH, 'o-', 'LineWidth', 2, 'Color', 'blue');
ylabel('Peak-To-Peak Amplitude (μV)');
xlabel('Time (minutes)');
title('Unsmoothed Slow-Wave Peak-To-Peak Amplitude and Blink Frequency per 5 Minutes');
grid on;

yyaxis right; % Activate right y-axis for blinks
plot(bin_centers / 60, BL_counts, 'o-', 'LineWidth', 2, 'Color', 'red');
ylabel('Count');

% Adjusting legend to include both time series
legend('SW P2P Amp', 'Blinks');

%%

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
avg_p2p_amp_allCH_sm = movmean(avg_p2p_amp_allCH, window_size);
BL_counts_sm = movmean(BL_counts, window_size);

%%

% Plot the smoothed time series in a new figure with two y-axes
figure;
yyaxis left; % Activate left y-axis for smoothed peak-to-peak amplitudes
plot(bin_centers / 60, avg_p2p_amp_allCH_sm, 'o-', 'LineWidth', 2, 'Color', 'blue');
ylabel('Peak-To-Peak Amplitude (Smoothed; μV)');
xlabel('Time (minutes)');
title('Smoothed Slow-Wave Peak-To-Peak Amplitude and Blink Frequency per 5 Minutes');
grid on;

yyaxis right; % Activate right y-axis for smoothed blinks
plot(bin_centers / 60, BL_counts_sm, 'o-', 'LineWidth', 2, 'Color', 'red');
ylabel('Count (Smoothed)');

% Adjusting legend to include both smoothed time series
legend('SW P2P Amp', 'Blinks');
