%% Setup

% load data
load('top10_filtered_results.mat'); % contains all metrics for SWs with top 10% P2P amps
load('Aligned.mat'); % contains smartphone tapping data (ad-hoc solution)

% assign struct array with smartphone tapping data to new var with more expressive name
tap_data = x; clear x;

% extract tap latencies (in ms) from 'tap_data'
taps = tap_data.Phone.Corrected{1,1}(:,2)';

% add directory with Ruchella's functions to search path
addpath(genpath('/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/src/microstates_functions'));

%% Extract inter-tap intervals (ITIs)

% calculate ITIs
[dt_dt, taps] = calculate_ITI_K_ITI_K1(taps);

%% Find taps within slow waves

% extract start and end times for slow waves
slow_wave_starts = cell2mat(top10_filtered_results.channels(1).negzx)';
slow_wave_ends = cell2mat(top10_filtered_results.channels(1).wvend)';

% determine taps within slow-wave intervals
tap_indices_within_sw = arrayfun(@(tap_time) any(tap_time >= slow_wave_starts & tap_time <= slow_wave_ends), taps);

% select corresponding ITIs
selected_dt_dt = dt_dt(tap_indices_within_sw, :);
% selected_dt_dt = dt_dt(~tap_indices_within_sw, :); % for taps outside of slow waves

%% Plot the JID

% determine the bin edges
gridx = linspace(1.5, 5, 50);

% create a JID plot of the selected ITIs
figure;
histogram2(selected_dt_dt(:, 1), selected_dt_dt(:, 2), ...
    'XBinEdges', gridx, 'YBinEdges', gridx, ...
    'DisplayStyle', 'tile', 'ShowEmptyBins', 'on', 'Normalization', 'pdf');
colormap("hot");
cb = colorbar;
ylabel(cb, 'Probability Density', 'FontSize', 11);
clim([0.0, 7.0]); % setting colormap limits for better comparison of JID plots
xlabel('ITI (K) [log10(ms)]');
ylabel('ITI (K+1) [log10(ms)]');
title('JID Plot for Taps Within Slow Waves (N = 150)');
% title('JID Plot for Taps Outside of Slow Waves (N = 1284)');

%% Extract inter-slow-wave intervals (ISWIs)

% % selecting the movie part of the recording
% slow_wave_starts = slow_wave_starts(slow_wave_starts < 4231882);

% % selecting the phone part of the recording
% slow_wave_starts = slow_wave_starts(slow_wave_starts >= 4231882);

% calculate ISWIs
[dt_dt, slow_wave_starts] = calculate_ITI_K_ITI_K1(slow_wave_starts');

%% Plot the JID

% determine the bin edges
gridx = linspace(1.5, 5, 50);

% create a JID plot of the ISWIs
figure;
histogram2(dt_dt(:, 1), dt_dt(:, 2), ...
    'XBinEdges', gridx, 'YBinEdges', gridx, ...
    'DisplayStyle', 'tile', 'ShowEmptyBins', 'on', 'Normalization', 'pdf'); % using pdf here
colormap("hot");
cb = colorbar;
ylabel(cb, 'Probability Density', 'FontSize', 11);
% clim([0.0, 2.0]); % setting colormap limits for better comparison of JID plots
xlabel('ISWI (K) [log10(ms)]');
ylabel('ISWI (K+1) [log10(ms)]');
title('JID Plot for Slow Waves');
% title('JID Plot for Slow Waves (Movie Part; N = 829)');
% title('JID Plot for Slow Waves (Phone Part; N = 451)');
