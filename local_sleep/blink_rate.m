eeglab nogui;

% load original EEG data
EEG = pop_loadset('filename', '12_57_07_05_18.set', 'filepath', '/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/AT08');

%%

% load processed and filtered data
load('top10_filtered_results.mat');

%% Does the blink rate increase surrounding the slow waves?

% extract blink times
blinks_t = unique([EEG.icaquant{1, 1}.artifactlatencies, EEG.icaquant{1, 2}.artifactlatencies]);

% extract slow-wave times for channel 1 (poszx = positive zero-crossing; middle of the wave)
slow_waves_t = cell2mat(top10_filtered_results.channels(1).poszx);

% extract recording duration (in ms)
rec_duration = EEG.pnts;

%%

% set parameters
bin_length = 4300; % length of each time bin in ms; chosen based on trial and error such that 'length_slow_waves' and 'length_outside_slow_waves' are about equal
half_bin_length = bin_length / 2;

% create time bins around the slow-wave times
time_bins = zeros(length(slow_waves_t), 2);
for i = 1:length(slow_waves_t)
    time_bins(i, 1) = max(1, slow_waves_t(i) - half_bin_length); % lower bound, not less than 1
    time_bins(i, 2) = min(rec_duration, slow_waves_t(i) + half_bin_length); % upper bound, not more than rec_duration
end

% merge overlapping time bins
merged_bins = merge_intervals(time_bins);

% get the complement of the merged bins to find times without slow waves
complement_bins = get_complement_intervals(merged_bins, rec_duration);

% count blinks in slow-wave and non-slow-wave periods
blinks_in_slow_waves = count_blinks_in_intervals(blinks_t, merged_bins);
blinks_outside_slow_waves = count_blinks_in_intervals(blinks_t, complement_bins);

% calculate the length of time in slow-wave and non-slow-wave periods
length_slow_waves = sum(merged_bins(:,2) - merged_bins(:,1) + 1);
length_outside_slow_waves = sum(complement_bins(:,2) - complement_bins(:,1) + 1);

% calculate average blink rates
avg_blink_rate_slow_waves = blinks_in_slow_waves / (length_slow_waves / 1000 / 60); % blinks per minute
avg_blink_rate_outside_slow_waves = blinks_outside_slow_waves / (length_outside_slow_waves / 1000 / 60); % blinks per minute

% display results
disp(['Average blink rate during slow-wave periods: ', num2str(avg_blink_rate_slow_waves), ' / min']);
disp(['Average blink rate during non-slow-wave periods: ', num2str(avg_blink_rate_outside_slow_waves), ' / min']);
