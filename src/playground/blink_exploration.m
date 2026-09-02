EEG = pop_loadset('07_41_25_04_18.set');

%%

% Choose target sampling rate
target_srate = 250;   % Hz; good default for 0.1–15 Hz analyses

% 1) Downsample
EEG = pop_resample(EEG, target_srate);
EEG = eeg_checkset(EEG);

% 2) Bandpass filter between 0.1 and 15 Hz
EEG = pop_eegfiltnew(EEG, ...
    'locutoff', 0.1, ...
    'hicutoff', 15);

EEG = eeg_checkset(EEG);

%%

% Compute vertical EOG derivation
vertical_eog = mean(EEG.data([35 49], :), 1) - mean(EEG.data([63 64], :), 1);

%%

% Plot random 30-second segment of vertical EOG
segment_duration_sec = 30;
segment_n_samples = round(segment_duration_sec * EEG.srate);

max_start_sample = length(vertical_eog) - segment_n_samples + 1;
start_sample = randi(max_start_sample);
end_sample = start_sample + segment_n_samples - 1;

t = (0:segment_n_samples-1) / EEG.srate;

figure;
plot(t, vertical_eog(start_sample:end_sample), 'k');
xlabel('Time within segment (s)');
ylabel('Vertical EOG amplitude (\muV)');
title(sprintf('Vertical EOG: random 30-s segment starting at %.2f s', ...
    start_sample / EEG.srate));
grid on;

%% Blink detection based on moving-window voltage range

% Assumes:
% - vertical_eog already exists
% - EEG.srate is defined
% - vertical_eog is in µV

% -----------------------------
% Parameters
% -----------------------------
blink_window_sec = 0.5;      % window over which max-min voltage is computed
threshold_factor = 6;        % robust threshold multiplier
min_blink_sec = 0.10;        % discard events shorter than this
merge_gap_sec = 0.25;        % merge events separated by less than this

% -----------------------------
% Moving-window peak-to-peak amplitude
% -----------------------------
blink_window_samples = round(blink_window_sec * EEG.srate);

moving_max = movmax(vertical_eog, blink_window_samples);
moving_min = movmin(vertical_eog, blink_window_samples);

moving_range = moving_max - moving_min;

% -----------------------------
% Robust threshold
% -----------------------------
range_median = median(moving_range, 'omitnan');
range_mad = mad(moving_range, 1);   % median absolute deviation

blink_threshold = range_median + threshold_factor * range_mad;

% Initial blink mask
blink_mask = moving_range > blink_threshold;

%% Convert blink mask into cleaned blink intervals

min_blink_samples = round(min_blink_sec * EEG.srate);
merge_gap_samples = round(merge_gap_sec * EEG.srate);

% Find starts and ends of detected regions
blink_diff = diff([false, blink_mask, false]);

blink_starts = find(blink_diff == 1);
blink_ends = find(blink_diff == -1) - 1;

% Remove very short events
blink_durations = blink_ends - blink_starts + 1;
keep_events = blink_durations >= min_blink_samples;

blink_starts = blink_starts(keep_events);
blink_ends = blink_ends(keep_events);

% Merge events that are very close together
if ~isempty(blink_starts)

    merged_starts = blink_starts(1);
    merged_ends = blink_ends(1);

    for i = 2:length(blink_starts)

        gap = blink_starts(i) - merged_ends(end);

        if gap <= merge_gap_samples
            merged_ends(end) = blink_ends(i);
        else
            merged_starts(end+1) = blink_starts(i);
            merged_ends(end+1) = blink_ends(i);
        end
    end

    blink_starts = merged_starts;
    blink_ends = merged_ends;
end

% Create final cleaned blink mask
blink_mask_clean = false(size(vertical_eog));

for i = 1:length(blink_starts)
    blink_mask_clean(blink_starts(i):blink_ends(i)) = true;
end

% Optional summary
fprintf('Detected %d blink events.\n', length(blink_starts));
fprintf('Blink threshold: %.2f µV moving range.\n', blink_threshold);

%% Plot random 30-second vertical EOG segment with blink highlights

segment_duration_sec = 30;
segment_n_samples = round(segment_duration_sec * EEG.srate);

max_start_sample = length(vertical_eog) - segment_n_samples + 1;
start_sample = randi(max_start_sample);
end_sample = start_sample + segment_n_samples - 1;

segment_idx = start_sample:end_sample;
t = (0:segment_n_samples-1) / EEG.srate;

segment_signal = vertical_eog(segment_idx);
segment_blink_mask = blink_mask_clean(segment_idx);

figure;
hold on;

% Plot signal
plot(t, segment_signal, 'k', 'LineWidth', 1);

% Get y-limits before highlighting
yl = ylim;

% Highlight blink sections
blink_diff_segment = diff([false, segment_blink_mask, false]);

segment_blink_starts = find(blink_diff_segment == 1);
segment_blink_ends = find(blink_diff_segment == -1) - 1;

for i = 1:length(segment_blink_starts)

    x_start = t(segment_blink_starts(i));
    x_end = t(segment_blink_ends(i));

    patch( ...
        [x_start x_end x_end x_start], ...
        [yl(1) yl(1) yl(2) yl(2)], ...
        [1 0.8 0.8], ...
        'EdgeColor', 'none', ...
        'FaceAlpha', 0.4 ...
    );
end

% Re-plot signal on top of highlights
plot(t, segment_signal, 'k', 'LineWidth', 1);

xlabel('Time within segment (s)');
ylabel('Vertical EOG amplitude (\muV)');

title(sprintf('Vertical EOG with blink detections: random 30-s segment starting at %.2f s', ...
    start_sample / EEG.srate));

grid on;
hold off;

%% Define condition windows in samples

% Condition times in minutes
movie_start_min = 39.6;
movie_end_min   = 109.2;

phone_start_min = 110.3;
phone_end_min   = 161.8;

% Convert to samples
movie_start_sample = round(movie_start_min * 60 * EEG.srate) + 1;
movie_end_sample   = round(movie_end_min   * 60 * EEG.srate);

phone_start_sample = round(phone_start_min * 60 * EEG.srate) + 1;
phone_end_sample   = round(phone_end_min   * 60 * EEG.srate);

% Safety: keep within signal boundaries
n_samples = length(vertical_eog);

movie_start_sample = max(movie_start_sample, 1);
movie_end_sample   = min(movie_end_sample, n_samples);

phone_start_sample = max(phone_start_sample, 1);
phone_end_sample   = min(phone_end_sample, n_samples);

%% Compute blink counts and blink rates

% Blink centers
blink_centers = round((blink_starts + blink_ends) / 2);

% Condition durations in minutes
movie_duration_min = (movie_end_sample - movie_start_sample + 1) / EEG.srate / 60;
phone_duration_min = (phone_end_sample - phone_start_sample + 1) / EEG.srate / 60;

% Count blinks whose center falls inside each condition
movie_blink_idx = blink_centers >= movie_start_sample & blink_centers <= movie_end_sample;
phone_blink_idx = blink_centers >= phone_start_sample & blink_centers <= phone_end_sample;

movie_n_blinks = sum(movie_blink_idx);
phone_n_blinks = sum(phone_blink_idx);

% Blink rates
movie_blink_rate = movie_n_blinks / movie_duration_min;
phone_blink_rate = phone_n_blinks / phone_duration_min;

% Print results
fprintf('\nBlink-rate summary\n');
fprintf('------------------\n');
fprintf('Movie condition: %d blinks over %.1f min = %.2f blinks/min\n', ...
    movie_n_blinks, movie_duration_min, movie_blink_rate);

fprintf('Phone condition: %d blinks over %.1f min = %.2f blinks/min\n', ...
    phone_n_blinks, phone_duration_min, phone_blink_rate);

%% Extract blink times per condition

% Blink center samples and times in minutes from recording start
blink_centers = round((blink_starts + blink_ends) / 2);
blink_times_min = blink_centers / EEG.srate / 60;

% Condition start/end times in minutes
movie_start_min = movie_start_sample / EEG.srate / 60;
movie_end_min   = movie_end_sample   / EEG.srate / 60;

phone_start_min = phone_start_sample / EEG.srate / 60;
phone_end_min   = phone_end_sample   / EEG.srate / 60;

% Blinks inside conditions
movie_blink_times = blink_times_min( ...
    blink_times_min >= movie_start_min & blink_times_min <= movie_end_min);

phone_blink_times = blink_times_min( ...
    blink_times_min >= phone_start_min & blink_times_min <= phone_end_min);

% Align to condition start
movie_blink_times_rel = movie_blink_times - movie_start_min;
phone_blink_times_rel = phone_blink_times - phone_start_min;

movie_duration_min = movie_end_min - movie_start_min;
phone_duration_min = phone_end_min - phone_start_min;

%% Blink raster plot: movie vs phone

figure;
hold on;

% Movie blinks
for i = 1:length(movie_blink_times_rel)
    x = movie_blink_times_rel(i);
    plot([x x], [1-0.3 1+0.3], 'k', 'LineWidth', 0.8);
end

% Phone blinks
for i = 1:length(phone_blink_times_rel)
    x = phone_blink_times_rel(i);
    plot([x x], [2-0.3 2+0.3], 'k', 'LineWidth', 0.8);
end

yticks([1 2]);
yticklabels({'Movie', 'Phone'});

xlabel('Time since condition start (min)');
ylabel('Condition');

title('Blink timing raster');

xlim([0 max(movie_duration_min, phone_duration_min)]);
ylim([0.5 2.5]);

grid on;
hold off;

%% Smoothed blink-rate curves

window_min = 5;          % sliding window size
step_min = 10 / 60;      % 10-second step

max_duration_min = max(movie_duration_min, phone_duration_min);
time_grid = 0:step_min:max_duration_min;

movie_rate = nan(size(time_grid));
phone_rate = nan(size(time_grid));

for i = 1:length(time_grid)

    t_center = time_grid(i);
    t_start = t_center - window_min / 2;
    t_end   = t_center + window_min / 2;

    % Only compute if full window lies inside condition
    if t_start >= 0 && t_end <= movie_duration_min
        movie_rate(i) = sum(movie_blink_times_rel >= t_start & ...
                            movie_blink_times_rel <  t_end) / window_min;
    end

    if t_start >= 0 && t_end <= phone_duration_min
        phone_rate(i) = sum(phone_blink_times_rel >= t_start & ...
                            phone_blink_times_rel <  t_end) / window_min;
    end
end

figure;
hold on;

plot(time_grid, movie_rate, 'LineWidth', 1.8);
plot(time_grid, phone_rate, 'LineWidth', 1.8);

xlabel('Time since condition start (min)');
ylabel('Blink rate (blinks/min)');

title(sprintf('Smoothed blink rate over time (%g-min window)', window_min));

legend({'Movie', 'Phone'}, 'Location', 'best');

xlim([0 max_duration_min]);
grid on;
hold off;

%% Combined blink raster and blink-rate visualization

figure;

% -----------------------------
% Top panel: blink raster
% -----------------------------
subplot(2, 1, 1);
hold on;

for i = 1:length(movie_blink_times_rel)
    x = movie_blink_times_rel(i);
    plot([x x], [1-0.3 1+0.3], 'k', 'LineWidth', 0.8);
end

for i = 1:length(phone_blink_times_rel)
    x = phone_blink_times_rel(i);
    plot([x x], [2-0.3 2+0.3], 'k', 'LineWidth', 0.8);
end

yticks([1 2]);
yticklabels({'Movie', 'Phone'});

ylabel('Condition');
title('Blink timing');

xlim([0 max_duration_min]);
ylim([0.5 2.5]);
grid on;
hold off;

% -----------------------------
% Bottom panel: smoothed rate
% -----------------------------
subplot(2, 1, 2);
hold on;

plot(time_grid, movie_rate, 'LineWidth', 1.8);
plot(time_grid, phone_rate, 'LineWidth', 1.8);

xlabel('Time since condition start (min)');
ylabel('Blink rate (blinks/min)');

title(sprintf('Smoothed blink rate (%g-min moving window)', window_min));

legend({'Movie', 'Phone'}, 'Location', 'best');

xlim([0 max_duration_min]);
grid on;
hold off;

%% Side-by-side summary plot: movie followed by phone

% Assumes these already exist:
% - blink_starts, blink_ends
% - EEG.srate
% - movie_start_sample, movie_end_sample
% - phone_start_sample, phone_end_sample

% -----------------------------
% Blink times
% -----------------------------
blink_centers = round((blink_starts + blink_ends) / 2);
blink_times_min = blink_centers / EEG.srate / 60;

% Condition timing in minutes from recording start
movie_start_min = movie_start_sample / EEG.srate / 60;
movie_end_min   = movie_end_sample   / EEG.srate / 60;

phone_start_min = phone_start_sample / EEG.srate / 60;
phone_end_min   = phone_end_sample   / EEG.srate / 60;

% Restrict to movie + phone period
analysis_start_min = movie_start_min;
analysis_end_min   = phone_end_min;

blink_times_analysis = blink_times_min( ...
    blink_times_min >= analysis_start_min & ...
    blink_times_min <= analysis_end_min);

% Express time relative to movie start
blink_times_rel = blink_times_analysis - analysis_start_min;

movie_start_rel = 0;
movie_end_rel   = movie_end_min - analysis_start_min;

phone_start_rel = phone_start_min - analysis_start_min;
phone_end_rel   = phone_end_min - analysis_start_min;

analysis_duration_min = analysis_end_min - analysis_start_min;

% -----------------------------
% Smoothed blink-rate curve
% -----------------------------
window_min = 5;          % sliding window size
step_min = 10 / 60;      % 10-second step

time_grid = 0:step_min:analysis_duration_min;
blink_rate = nan(size(time_grid));

for i = 1:length(time_grid)

    t_center = time_grid(i);
    t_start = t_center - window_min / 2;
    t_end   = t_center + window_min / 2;

    if t_start >= 0 && t_end <= analysis_duration_min
        blink_rate(i) = sum(blink_times_rel >= t_start & ...
                            blink_times_rel <  t_end) / window_min;
    end
end

% -----------------------------
% Plot
% -----------------------------
figure;

% =============================
% Top panel: blink raster
% =============================
subplot(2, 1, 1);
hold on;

% Light condition background shading
yl = [0 1];

patch([movie_start_rel movie_end_rel movie_end_rel movie_start_rel], ...
      [yl(1) yl(1) yl(2) yl(2)], ...
      [0.9 0.9 0.9], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.4);

patch([phone_start_rel phone_end_rel phone_end_rel phone_start_rel], ...
      [yl(1) yl(1) yl(2) yl(2)], ...
      [0.8 0.8 0.8], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.4);

% Blink ticks
for i = 1:length(blink_times_rel)
    x = blink_times_rel(i);
    plot([x x], [0.25 0.75], 'k', 'LineWidth', 0.8);
end

% Condition boundary
xline(movie_end_rel, '--k', 'Movie end', 'LabelVerticalAlignment', 'bottom');
xline(phone_start_rel, '--k', 'Phone start', 'LabelVerticalAlignment', 'top');

yticks([]);
ylabel('Blinks');

title('Blink timing across movie and phone conditions');

xlim([0 analysis_duration_min]);
ylim(yl);

% Condition labels
text(mean([movie_start_rel movie_end_rel]), 0.95, 'Movie', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontWeight', 'bold');

text(mean([phone_start_rel phone_end_rel]), 0.95, 'Phone', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontWeight', 'bold');

grid on;
hold off;

% =============================
% Bottom panel: blink rate curve
% =============================
subplot(2, 1, 2);
hold on;

% Background shading
yl_rate = [0 max(blink_rate, [], 'omitnan') * 1.15];

if yl_rate(2) == 0 || isnan(yl_rate(2))
    yl_rate = [0 1];
end

patch([movie_start_rel movie_end_rel movie_end_rel movie_start_rel], ...
      [yl_rate(1) yl_rate(1) yl_rate(2) yl_rate(2)], ...
      [0.9 0.9 0.9], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.4);

patch([phone_start_rel phone_end_rel phone_end_rel phone_start_rel], ...
      [yl_rate(1) yl_rate(1) yl_rate(2) yl_rate(2)], ...
      [0.8 0.8 0.8], ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.4);

% Blink-rate curve
plot(time_grid, blink_rate, 'k', 'LineWidth', 1.8);

% Condition boundary
xline(movie_end_rel, '--k');
xline(phone_start_rel, '--k');

xlabel('Time since movie start (min)');
ylabel('Blink rate (blinks/min)');

title(sprintf('Smoothed blink rate over time (%g-min moving window)', window_min));

xlim([0 analysis_duration_min]);
ylim(yl_rate);

grid on;
hold off;

%% Side-by-side summary plot: movie followed by phone, colored

% Assumes these already exist:
% - blink_starts, blink_ends
% - EEG.srate
% - movie_start_sample, movie_end_sample
% - phone_start_sample, phone_end_sample

% -----------------------------
% Colors
% -----------------------------
movie_color = [0.20 0.45 0.90];   % blue
phone_color = [0.90 0.20 0.20];   % red

% -----------------------------
% Blink times
% -----------------------------
blink_centers = round((blink_starts + blink_ends) / 2);
blink_times_min = blink_centers / EEG.srate / 60;

% Condition timing in minutes from recording start
movie_start_min = movie_start_sample / EEG.srate / 60;
movie_end_min   = movie_end_sample   / EEG.srate / 60;

phone_start_min = phone_start_sample / EEG.srate / 60;
phone_end_min   = phone_end_sample   / EEG.srate / 60;

% Restrict to movie + phone period
analysis_start_min = movie_start_min;
analysis_end_min   = phone_end_min;

blink_times_analysis = blink_times_min( ...
    blink_times_min >= analysis_start_min & ...
    blink_times_min <= analysis_end_min);

% Express time relative to movie start
blink_times_rel = blink_times_analysis - analysis_start_min;

movie_start_rel = 0;
movie_end_rel   = movie_end_min - analysis_start_min;

phone_start_rel = phone_start_min - analysis_start_min;
phone_end_rel   = phone_end_min - analysis_start_min;

analysis_duration_min = analysis_end_min - analysis_start_min;

% -----------------------------
% Smoothed blink-rate curve
% -----------------------------
window_min = 5;          % sliding window size
step_min = 10 / 60;      % 10-second step

time_grid = 0:step_min:analysis_duration_min;
blink_rate = nan(size(time_grid));

for i = 1:length(time_grid)

    t_center = time_grid(i);
    t_start = t_center - window_min / 2;
    t_end   = t_center + window_min / 2;

    if t_start >= 0 && t_end <= analysis_duration_min
        blink_rate(i) = sum(blink_times_rel >= t_start & ...
                            blink_times_rel <  t_end) / window_min;
    end
end

% -----------------------------
% Plot
% -----------------------------
figure;

% =============================
% Top panel: blink raster
% =============================
subplot(2, 1, 1);
hold on;

yl = [0 1];

% Condition background shading
patch([movie_start_rel movie_end_rel movie_end_rel movie_start_rel], ...
      [yl(1) yl(1) yl(2) yl(2)], ...
      movie_color, ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.18);

patch([phone_start_rel phone_end_rel phone_end_rel phone_start_rel], ...
      [yl(1) yl(1) yl(2) yl(2)], ...
      phone_color, ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.18);

% Blink ticks, colored by condition
for i = 1:length(blink_times_rel)
    x = blink_times_rel(i);

    if x >= movie_start_rel && x <= movie_end_rel
        tick_color = movie_color;
    elseif x >= phone_start_rel && x <= phone_end_rel
        tick_color = phone_color;
    else
        tick_color = [0 0 0];   % gap between conditions
    end

    plot([x x], [0.25 0.75], ...
        'Color', tick_color, ...
        'LineWidth', 0.8);
end

% Condition boundaries, without labels
xline(movie_end_rel, '--k');
xline(phone_start_rel, '--k');

yticks([]);
ylabel('Blinks');

title('Blink timing across movie and phone conditions');

xlim([0 analysis_duration_min]);
ylim(yl);

% Condition labels
text(mean([movie_start_rel movie_end_rel]), 0.95, 'Movie', ...
    'Color', 'k', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontWeight', 'bold');

text(mean([phone_start_rel phone_end_rel]), 0.95, 'Phone', ...
    'Color', 'k', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontWeight', 'bold');

grid on;
hold off;

% =============================
% Bottom panel: blink rate curve
% =============================
subplot(2, 1, 2);
hold on;

yl_rate = [0 max(blink_rate, [], 'omitnan') * 1.15];

if yl_rate(2) == 0 || isnan(yl_rate(2))
    yl_rate = [0 1];
end

% Background shading
patch([movie_start_rel movie_end_rel movie_end_rel movie_start_rel], ...
      [yl_rate(1) yl_rate(1) yl_rate(2) yl_rate(2)], ...
      movie_color, ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.18);

patch([phone_start_rel phone_end_rel phone_end_rel phone_start_rel], ...
      [yl_rate(1) yl_rate(1) yl_rate(2) yl_rate(2)], ...
      phone_color, ...
      'EdgeColor', 'none', ...
      'FaceAlpha', 0.18);

% Blink-rate curve
plot(time_grid, blink_rate, 'k', 'LineWidth', 1.8);

% Optional: colored condition-specific curves on top
movie_rate_mask = time_grid >= movie_start_rel & time_grid <= movie_end_rel;
phone_rate_mask = time_grid >= phone_start_rel & time_grid <= phone_end_rel;

plot(time_grid(movie_rate_mask), blink_rate(movie_rate_mask), ...
    'Color', movie_color, ...
    'LineWidth', 2.2);

plot(time_grid(phone_rate_mask), blink_rate(phone_rate_mask), ...
    'Color', phone_color, ...
    'LineWidth', 2.2);

% Condition boundaries, without labels
xline(movie_end_rel, '--k');
xline(phone_start_rel, '--k');

xlabel('Time since movie start (min)');
ylabel('Blink rate (blinks/min)');

title(sprintf('Smoothed blink rate over time (%g-min moving window)', window_min));

xlim([0 analysis_duration_min]);
ylim(yl_rate);

grid on;
hold off;

%% One-time setup for blink-vs-slow-wave visualization

% -------------------------------------------------------------------------
% Preserve current blink-preprocessed EEG and blink variables
% -------------------------------------------------------------------------
EEG_blink = EEG;

% Assumes these already exist from previous sections:
% - vertical_eog
% - blink_mask_clean
% - blink_starts
% - blink_ends

vertical_eog_blink = vertical_eog;
blink_mask_clean_blink = blink_mask_clean;

% -------------------------------------------------------------------------
% Reload original .set file for slow-wave-style preprocessing
% -------------------------------------------------------------------------
EEG_sw = pop_loadset('filename', '07_41_25_04_18.set', 'filepath', pwd);
EEG_sw = eeg_checkset(EEG_sw);

% -------------------------------------------------------------------------
% Copy preprocessing strategy from slow-wave pipeline
% -------------------------------------------------------------------------

% Band-pass filtering: 0.5–48 Hz
EEG_sw = pop_eegfiltnew(EEG_sw, ...
    'locutoff', 0.5, ...
    'hicutoff', 48);

% Downsample to 128 Hz
EEG_sw = pop_resample(EEG_sw, 128);
EEG_sw = eeg_checkset(EEG_sw);

% Re-reference to average of all channels
EEG_sw = pop_reref(EEG_sw, []);
EEG_sw = eeg_checkset(EEG_sw);

% Re-reference to average of mastoid electrodes, keeping reference channels
EEG_sw = pop_reref(EEG_sw, [52 58], 'keepref', 'on');
EEG_sw = eeg_checkset(EEG_sw);

% Low-pass filter below 4 Hz
EEG_sw = pop_eegfiltnew(EEG_sw, ...
    'locutoff', [], ...
    'hicutoff', 4);

EEG_sw = eeg_checkset(EEG_sw);

% Extract preprocessed channel 1
sw_ch1 = double(EEG_sw.data(1, :));

fprintf('Slow-wave preprocessing complete.\n');
fprintf('Slow-wave signal sampling rate: %.1f Hz\n', EEG_sw.srate);