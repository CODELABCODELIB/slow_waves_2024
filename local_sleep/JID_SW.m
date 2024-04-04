%% Setup

% load data
load('top10_filtered_results.mat'); % contains all metrics for SWs with top 10% P2P amps
load('Aligned.mat'); % contains smartphone tapping data (ad-hoc solution)

% assign struct array with smartphone tapping data to new var with more expressive name
tap_data = x; clear x;

% extract vector with tap latencies (in ms) from 'tap_data' and transpose it
taps = tap_data.Phone.Corrected{1,1}(:,2)';

% add directory with Ruchella's functions to search path
addpath(genpath('/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/src/microstates_functions'));

%% Extract inter-tap intervals (ITIs)

% calculate ITIs
[dt_dt, taps] = calculate_ITI_K_ITI_K1(taps);

% assign triads of taps to corresponding JID bins
[dt_dt, gridx, xi] = assign_tap2bin(dt_dt);

%% Find taps within slow waves

% Extract start and end times for slow waves
slow_wave_starts = cell2mat(top10_filtered_results.channels(1).negzx)';
slow_wave_ends = cell2mat(top10_filtered_results.channels(1).wvend)';

% Determine taps within slow-wave intervals
tap_indices_within_sw = arrayfun(@(tap_time) any(tap_time >= slow_wave_starts & tap_time <= slow_wave_ends), taps);

% Select corresponding ITIs
selected_dt_dt = dt_dt(tap_indices_within_sw, :);

%% Plot the JID

% Create a JID plot of the selected ITIs
figure;
histogram2(selected_dt_dt(:, 3), selected_dt_dt(:, 4), ...
    'XBinEdges', gridx, 'YBinEdges', gridx, ...
    'DisplayStyle', 'tile', 'ShowEmptyBins', 'on', 'Normalization', 'count');
colormap("hot");
colorbar;
xlabel('ITI (K) [log10(ms)]');
ylabel('ITI (K+1) [log10(ms)]');
title('JID Plot for Taps Within Slow Waves (N = 150)');
