eeglab nogui;

% load original EEG data
EEG = pop_loadset('filename', '12_57_07_05_18.set', 'filepath', '/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/AT08');

%%

% load processed and filtered data
load('top10_filtered_results.mat');

%%

% extract blink times
blinks_t = unique([EEG.icaquant{1, 1}.artifactlatencies, EEG.icaquant{1, 2}.artifactlatencies]);

% extract slow-wave times for channel 1
SW_start_t = cell2mat(top10_filtered_results.channels(1).negzx);
SW_end_t = cell2mat(top10_filtered_results.channels(1).wvend);

% extract recording duration (in ms)
rec_duration = EEG.pnts;

% extract sampling rate
sampling_rate = EEG.srate;

%% Exploration of the latencies between blink times and preceeding slow-wave starts

% % initialize an array for the latencies
% t_diff_SW_BL = [];
% 
% % compute the latencies
% for b = 1:length(blinks_t)
%     if blinks_t(b) > SW_start_t(1)
%         SW_start_t_before = SW_start_t(SW_start_t < blinks_t(b));
%         t_diff_SW_BL(b) = blinks_t(b) - SW_start_t_before(end);
%     end
% end
% 
% % compute descriptive statistics
% m_t_diff_sec = mean(t_diff_SW_BL) / 1000;
% disp(m_t_diff_sec)
% sd_t_diff_sec = std(t_diff_SW_BL) / 1000;
% disp(sd_t_diff_sec)
% 
% % create a histogram for the latencies
% % histogram(t_diff_SW_BL / 1000)
% 
% % convert blink times to min
% blinks_t_min = blinks_t / 1000 / 60;
% 
% % determine the number of 5-min bins required
% max_time = max(blinks_t_min);
% num_bins = ceil(max_time / 5);
% 
% % initialize arrays to store binned times and latencies
% binned_times = (1:num_bins) * 5 - 2.5; % center of each bin
% binned_latencies = zeros(1, num_bins);
% 
% for bin = 1:num_bins
%     bin_start = (bin - 1) * 5;
%     bin_end = bin * 5;
%     bin_indices = blinks_t_min > bin_start & blinks_t_min <= bin_end;
%     bin_latencies = t_diff_SW_BL(bin_indices) / 1000; % Convert to seconds
%     binned_latencies(bin) = mean(bin_latencies);
% end
% 
% % plot time series
% figure;
% plot(binned_times, binned_latencies, 'o-');
% title('Unsmoothed Time-Series Plot of Binned Blink Latencies');
% xlabel('Time (min)');
% ylabel('Latency to Preceding Slow-Wave Start (s)');
% 
% window_size = 5;
% binned_latencies_sm = movmean(binned_latencies, window_size);
% 
% % plot time series
% figure;
% plot(binned_times, binned_latencies_sm, 'o-');
% title('Smoothed Time-Series Plot of Binned Blink Latencies');
% xlabel('Time (min)');
% ylabel('Latency to Preceding Slow-Wave Start (s)');

%%

% define the interval duration in min
interval_duration_min = 1;

% convert min to ms
interval_duration_ms = interval_duration_min * 60 * 1000;

% find the latest possible start time for the interval
latest_start_time = rec_duration - interval_duration_ms;

% generate a random start time for the interval
rand_start_ms = randi([0 latest_start_time]);

% convert start and end time of the interval to points
interval_start_point = rand_start_ms;
interval_end_point = rand_start_ms + interval_duration_ms;

% filter times to include only those within the interval
blinks_t_interval = blinks_t(blinks_t >= interval_start_point & blinks_t <= interval_end_point);
SW_start_t_interval = SW_start_t(SW_start_t >= interval_start_point & SW_start_t <= interval_end_point);
SW_end_t_interval = SW_end_t(SW_end_t >= interval_start_point & SW_end_t <= interval_end_point);

% create a plot
figure;
hold on;

% time axis
time_axis = linspace(0, interval_duration_min * 60, interval_duration_ms * (sampling_rate/1000));

% plot blink times
for i = 1:length(blinks_t_interval)
    xline((blinks_t_interval(i)-rand_start_ms)/(1000), 'Color', 'blue', 'LineWidth', 2);
end

% plot slow-wave start times
for i = 1:length(SW_start_t_interval)
    xline((SW_start_t_interval(i)-rand_start_ms)/(1000), 'Color', 'yellow', 'LineWidth', 2);
end

% plot slow-wave end times
for i = 1:length(SW_end_t_interval)
    xline((SW_end_t_interval(i)-rand_start_ms)/(1000), 'Color', 'red', 'LineWidth', 2);
end

% dummy plots for legend
h1 = plot(NaN,NaN,'-b', 'LineWidth', 2);
h2 = plot(NaN,NaN,'-y', 'LineWidth', 2);
h3 = plot(NaN,NaN,'-r', 'LineWidth', 2);

% convert 'rand_start_ms' to sec
rand_start_s = rand_start_ms / 1000;

% calculate h, min, and sec
hours = floor(rand_start_s / 3600);
minutes = floor(mod(rand_start_s, 3600) / 60);
seconds = mod(rand_start_s, 60);

xlabel('Time (Seconds)', 'FontSize', 14);
set(gca, 'YTick', [], 'YColor', 'none');
title_str = sprintf('Event Times in a Random %d-Minute Interval Starting at %02d:%02d:%02d', interval_duration_min, hours, minutes, round(seconds));
title(title_str, 'FontSize', 16);
xlim([0 interval_duration_min * 60]);
lg = legend([h1, h2, h3], {'Blink', 'Slow-Wave Start', 'Slow-Wave End'}, 'Location', 'northeast');
set(lg, 'FontSize', 12);
hold off;
