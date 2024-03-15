% load processed and filtered data
load('top10_filtered_results.mat');

%%
eeglab nogui;

% load original EEG data
EEG = pop_loadset('filename', '12_57_07_05_18.set', 'filepath', '/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/AT08');

%%

% extract slow-wave times for channel 1 (poszx = positive zero-crossing; middle of the wave)
slow_waves_t = cell2mat(top10_filtered_results.channels(1).poszx);

% extract blink times
blinks_t = unique([EEG.icaquant{1, 1}.artifactlatencies, EEG.icaquant{1, 2}.artifactlatencies]);

%%

% Define bin edges (5-minute bins in seconds)
recording_duration_seconds = top10_filtered_results.channels(1).datalength / 128; % 128 = fs of downsampled EEG data
bin_edges = 0:300:recording_duration_seconds; % 300 seconds = 5 minutes

% Convert 'slow_waves_t' and 'blinks_t' into seconds
slow_waves_t_sec = slow_waves_t / 1000;
blinks_t_sec = blinks_t / 1000;
    
% Count the slow-wave/blink occurrences in each bin
[SW_counts, ~] = histcounts(slow_waves_t_sec, bin_edges);
[BL_counts, ~] = histcounts(blinks_t_sec, bin_edges);

%%

% Plot the unsmoothed time series with two different y-axes
figure;
yyaxis left; % Activate left y-axis for slow waves
bin_centers = bin_edges(1:end-1) + diff(bin_edges) / 2;
plot(bin_centers / 60, SW_counts, 'o-', 'LineWidth', 2, 'Color', 'blue');
ylabel('Count');
xlabel('Time (minutes)');
title('Unsmoothed Slow-Wave and Blink Frequency per 5 Minutes');
grid on;

yyaxis right; % Activate right y-axis for blinks
plot(bin_centers / 60, BL_counts, 'o-', 'LineWidth', 2, 'Color', 'red');
ylabel('Count');

% Adjusting legend to include both time series
legend('Slow Waves', 'Blinks');

%%

% Calculate the moving average for the counts with a specified window size
window_size = 5; % Size of the moving window
SW_counts_sm = movmean(SW_counts, window_size);
BL_counts_sm = movmean(BL_counts, window_size); % Also smooth the blink counts

%%

% Plot the smoothed time series in a new figure with two y-axes
figure;
yyaxis left; % Activate left y-axis for smoothed slow waves
plot(bin_centers / 60, SW_counts_sm, 'o-', 'LineWidth', 2, 'Color', 'blue');
ylabel('Count (Smoothed)');
xlabel('Time (minutes)');
title('Smoothed Slow-Wave and Blink Frequency per 5 Minutes');
grid on;

yyaxis right; % Activate right y-axis for smoothed blinks
plot(bin_centers / 60, BL_counts_sm, 'o-', 'LineWidth', 2, 'Color', 'red');
ylabel('Count (Smoothed)');

% Adjusting legend to include both smoothed time series
legend('Slow Waves', 'Blinks');
