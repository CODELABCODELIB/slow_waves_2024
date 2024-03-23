eeglab nogui;

% Load the EEG dataset
EEG = pop_loadset('filename', '12_57_07_05_18.set', 'filepath', '/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/AT08');

%%

% Calculate the number of data points in 5-minute bins
bin_length_sec = 300; % 5 minutes in seconds
points_per_bin = bin_length_sec * EEG.srate; % Number of data points in each bin

% Calculate the total number of bins in the recording
total_bins = floor(length(EEG.data) / points_per_bin);

% Initialize array to store average delta power for each bin
delta_power_per_bin = zeros(1, total_bins);

% Loop through each bin
for bin = 1:total_bins
    % Extract data for the current bin
    bin_data = EEG.data(:, (bin - 1) * points_per_bin + 1 : bin * points_per_bin);
    
    % Compute the spectral power of the current bin
    [spectra, freqs] = spectopo(bin_data, 0, EEG.srate, 'plot', 'off');
    
    % Find indices of 1-4 Hz frequencies
    idx = find(freqs >= 1 & freqs <= 4);
    
    % Calculate average delta power for this bin
    delta_power_per_bin(bin) = mean(mean(spectra(:, idx)));
end

% Define the time vector for plotting (in minutes)
time_vector_minutes = (1:total_bins) * (bin_length_sec / 60);

%%

% Plot the unsmoothed time series of the average delta power
figure;
plot(time_vector_minutes, delta_power_per_bin, 'o-', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Average Power in 1-4 Hz (dB)');
title('Unsmoothed Time Series of Delta Power (1-4 Hz) Over 5-Min Bins');
grid on;

%%

% Calculate the moving average for the power values with a specified window size
window_size = 5; % Size of the moving window
delta_power_per_bin_sm = movmean(delta_power_per_bin, window_size);

%%

% Plot the smoothed time series of the average delta power
figure;
plot(time_vector_minutes, delta_power_per_bin_sm, 'o-', 'LineWidth', 2);
xlabel('Time (minutes)');
ylabel('Average Power in 1-4 Hz (dB)');
title('Smoothed Time Series of Delta Power (1-4 Hz) Over 5-Min Bins');
grid on;
