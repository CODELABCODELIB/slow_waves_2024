%% Get slow-wave times

load('top10_filtered_results.mat');
fields = fieldnames(top10_filtered_results.channels);

movie_end = 4231882;
phone_end = 7101108;

phone_waves = top10_filtered_results;

for ch = 1:length(phone_waves.channels)
    idx_keep = cell2mat(phone_waves.channels(ch).negzx) > movie_end & cell2mat(phone_waves.channels(ch).negzx) <= phone_end;
    for field_idx = 1:length(fields)
        field = fields{field_idx};
        if field_idx == 1
            phone_waves.channels(ch).(field) = round((phone_end - movie_end) * 0.128);
        else
            phone_waves.channels(ch).(field) = phone_waves.channels(ch).(field)(idx_keep);
        end
    end
end

%% Get blink times

eeglab nogui;

EEG = pop_loadset('filename', '12_57_07_05_18.set', 'filepath', '/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/Test Data');

blink_t = unique([EEG.icaquant{1, 1}.artifactlatencies, EEG.icaquant{1, 2}.artifactlatencies]);
blink_t = blink_t(blink_t > movie_end & blink_t <= phone_end);

%% Get tap times

load('Aligned.mat');
tap_data = x; clear x;
tap_t = tap_data.Phone.Corrected{1,1}(:,2)';
tap_t = tap_t(tap_t > movie_end & tap_t <= phone_end);

%% Calculate time-lagged correlations between taps/blinks & slow waves

% Defining the maximum lag
max_lag = 8;

% Creating lag vector
lags = -max_lag:max_lag;

% Pre-allocate matrices for time-lagged correlation coefficients and corresponding p-values
lagged_rhos = zeros(64, length(lags));
lagged_pvals = zeros(64, length(lags));

% Loop through channels
for ch = 1:length(phone_waves.channels)
% for ch = 5
    
    % Extract wave starts
    SW_t = cell2mat(phone_waves.channels(ch).negzx);
    
    % Define number of bins
    bins = 100;
    
    % Calculate bin edges and bin centers
    bin_edges = linspace(movie_end + 1, phone_end, bins + 1); % X bins -> X+1 edges
    
    % Count occurrences in each bin
    SW_counts = histcounts(SW_t, bin_edges);
    blink_counts = histcounts(blink_t, bin_edges);
    tap_counts = histcounts(tap_t, bin_edges);
    
    % Initialize counter
    counter = 0;
    
    % Loop through lags
    for lag = lags
    % for lag = -12
        
        % Update counter
        counter = counter + 1;
        
        if lag < 0
            tap_counts_shifted = tap_counts((1+abs(lag)):bins);
            % blink_counts_shifted = blink_counts((1+abs(lag)):bins);
            SW_counts_shifted = SW_counts(1:(bins-abs(lag)));
        elseif lag > 0
            tap_counts_shifted = tap_counts(1:(bins-lag));
            % blink_counts_shifted = blink_counts(1:(bins-lag));
            SW_counts_shifted = SW_counts((1+lag):bins);
        else
            tap_counts_shifted = tap_counts;
            % blink_counts_shifted = blink_counts;
            SW_counts_shifted = SW_counts;
        end
        
        % Calculate correlation coefficient
        % [rho, pval] = corr(tap_counts_shifted', SW_counts_shifted', 'type', 'Pearson');
        [rho, pval] = corr(tap_counts_shifted', SW_counts_shifted', 'type', 'Spearman');
        % [rho, pval] = corr(blink_counts_shifted', SW_counts_shifted', 'type', 'Pearson');
        % [rho, pval] = corr(blink_counts_shifted', SW_counts_shifted', 'type', 'Spearman');
        
        % Insert time-lagged correlation coefficients and corresponding p-values into pre-allocated matrices
        lagged_rhos(ch, counter) = rho;
        lagged_pvals(ch, counter) = pval;
        
    end
    
end

%% Calculate time-lagged correlations between taps & blinks

% Defining the maximum lag
max_lag = 8;

% Creating lag vector
lags = -max_lag:max_lag;

% Pre-allocate matrices for time-lagged correlation coefficients and corresponding p-values
lagged_rhos = zeros(1, length(lags));
lagged_pvals = zeros(1, length(lags));

% Define number of bins
bins = 100;

% Calculate bin edges and bin centers
bin_edges = linspace(movie_end + 1, phone_end, bins + 1); % X bins -> X+1 edges

% Count occurrences in each bin
blink_counts = histcounts(blink_t, bin_edges);
tap_counts = histcounts(tap_t, bin_edges);

% Initialize counter
counter = 0;

% Loop through lags
for lag = lags
    
    % Update counter
    counter = counter + 1;
    
    if lag < 0
        tap_counts_shifted = tap_counts((1+abs(lag)):bins);
        blink_counts_shifted = blink_counts(1:(bins-abs(lag)));
    elseif lag > 0
        tap_counts_shifted = tap_counts(1:(bins-lag));
        blink_counts_shifted = blink_counts((1+lag):bins);
    else
        tap_counts_shifted = tap_counts;
        blink_counts_shifted = blink_counts;
    end
    
    % Calculate correlation coefficient
    % [rho, pval] = corr(tap_counts_shifted', blink_counts_shifted', 'type', 'Pearson');
    [rho, pval] = corr(tap_counts_shifted', blink_counts_shifted', 'type', 'Spearman');
    
    % Insert time-lagged correlation coefficients and corresponding p-values into pre-allocated matrices
    lagged_rhos(1, counter) = rho;
    lagged_pvals(1, counter) = pval;
    
end

%% Timeseries plot

% Z-transform the counts
SW_z = (SW_counts_shifted - mean(SW_counts_shifted)) / std(SW_counts_shifted);
blink_z = (blink_counts - mean(blink_counts)) / std(blink_counts);
tap_z = (tap_counts_shifted - mean(tap_counts_shifted)) / std(tap_counts_shifted);

% Define bin serial numbers
bin_numbers = 1:38; % needs to be adjusted for every case

% Plotting the time series
figure;
hold on;
plot(bin_numbers, SW_z, 'r', 'DisplayName', 'Slow-wave counts (z-score)');
plot(bin_numbers, blink_z, 'g', 'DisplayName', 'Blink counts (z-score)');
plot(bin_numbers, tap_z, 'b', 'DisplayName', 'Tap counts (z-score)');

% Adding labels and legend
xlabel('Bin Number');
ylabel('Z-score');
title('Time Series Line Plot of Slow-wave, Blink, and Tap Counts');
legend;
hold off;

%% Holm-Bonferroni correction

% % Reshape the p-value matrix to a vector
% p_values = lagged_pvals(:);
% 
% % Number of hypotheses/tests
% m = length(p_values);
% 
% % Sort the p-values in ascending order
% [sorted_p, sort_idx] = sort(p_values);
% 
% % Holm-Bonferroni adjustment
% adjusted_p = zeros(1, m);
% for i = 1:m
%     adjusted_p(i) = min(1, sorted_p(i) * (m - i + 1));
% end
% 
% % Reorder adjusted p-values to the original order
% reordered_adjusted_p = adjusted_p;
% reordered_adjusted_p(sort_idx) = adjusted_p;
% 
% % Significance check
% significant = reordered_adjusted_p < 0.05;
% 
% % Copy the coefficient matrix
% masked_lagged_rhos = lagged_rhos;
% 
% % Turn all non-significant coefficients to zeros
% masked_lagged_rhos(~significant) = 0;

%% FDR adjustment (Benjamini-Hochberg procedure)

% % Reshape the p-value matrix to a vector
% p_values = lagged_pvals(:);
% 
% % Number of comparisons
% m = length(p_values);
% 
% % Desired FDR level (e.g., 0.05)
% alpha = 0.05;
% 
% % Sort the p-values and store the original indices
% [sorted_p_values, sort_idx] = sort(p_values);
% 
% % Compute the Benjamini-Hochberg critical values
% bh_critical_values = (1:m)' * (alpha / m);
% 
% % Determine the maximum p-value that is less than the critical value
% significant = sorted_p_values <= bh_critical_values;
% 
% % Reorder (non-)significant p-values (0|1) to the original order
% reordered_significant = significant;
% reordered_significant(sort_idx) = significant;
% 
% % Copy the coefficient matrix
% masked_lagged_rhos = lagged_rhos;
% 
% % Turn all non-significant coefficients to zeros
% masked_lagged_rhos(~reordered_significant) = 0;

%% Masking

% Copy the coefficient matrix
masked_lagged_rhos = lagged_rhos;

% Mask the coefficient matrix such that only significant coefficients (p < .05) are retained
masked_lagged_rhos(lagged_pvals >= 0.01) = 0;
% masked_lagged_rhos(lagged_pvals >= 0.05) = 0;

% Transform all coefficients to their absolute value
masked_lagged_rhos_abs = abs(masked_lagged_rhos);

% Calculate the column sums of the absolute values of the coefficients
col_sums = sum(masked_lagged_rhos_abs, 1);

% Calculate the binary (1 = sign., 0 = non-sign.) column sums of the coefficients
col_sums_binary = sum(masked_lagged_rhos ~= 0);

%% Create topoplots

visualize_corr(masked_lagged_rhos, max_lag, EEG.chanlocs);