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

%% Get tap times

load('Aligned.mat');
tap_data = x; clear x;
tap_t = tap_data.Phone.Corrected{1,1}(:,2)';
tap_t = tap_t(tap_t > movie_end & tap_t <= phone_end);

%% Blinks/taps autocorrelations

% Defining the maximum lag
max_lag = 26;

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
% tap_counts = histcounts(tap_t, bin_edges);

% Initialize counter
counter = 0;

% Loop through lags
for lag = lags
    
    % Update counter
    counter = counter + 1;
    
    if lag < 0
        % tap_counts_shifted1 = tap_counts((1+abs(lag)):bins);
        % tap_counts_shifted2 = tap_counts(1:(bins-abs(lag)));
        blink_counts_shifted1 = blink_counts((1+abs(lag)):bins);
        blink_counts_shifted2 = blink_counts(1:(bins-abs(lag)));
    elseif lag > 0
        % tap_counts_shifted1 = tap_counts(1:(bins-lag));
        % tap_counts_shifted2 = tap_counts((1+lag):bins);
        blink_counts_shifted1 = blink_counts(1:(bins-lag));
        blink_counts_shifted2 = blink_counts((1+lag):bins);
    else
        % tap_counts_shifted1 = tap_counts;
        % tap_counts_shifted2 = tap_counts;
        blink_counts_shifted1 = blink_counts;
        blink_counts_shifted2 = blink_counts;
    end
    
    % Calculate correlation coefficient
    % [rho, pval] = corr(tap_counts_shifted1', tap_counts_shifted2', 'type', 'Pearson');
    % [rho, pval] = corr(tap_counts_shifted1', tap_counts_shifted2', 'type', 'Spearman');
    [rho, pval] = corr(blink_counts_shifted1', blink_counts_shifted2', 'type', 'Pearson');
    % [rho, pval] = corr(blink_counts_shifted1', blink_counts_shifted2', 'type', 'Spearman');
    
    % Insert time-lagged correlation coefficients and corresponding p-values into pre-allocated matrices
    lagged_rhos(1, counter) = rho;
    lagged_pvals(1, counter) = pval;
    
end

%% Slow waves autocorrelations

% Defining the maximum lag
max_lag = 26;

% Creating lag vector
lags = -max_lag:max_lag;

% Pre-allocate matrices for time-lagged correlation coefficients and corresponding p-values
lagged_rhos = zeros(64, length(lags));
lagged_pvals = zeros(64, length(lags));

% Loop through channels
for ch = 1:length(phone_waves.channels)
    
    % Extract wave starts
    SW_t = cell2mat(phone_waves.channels(ch).negzx);
    
    % Define number of bins
    bins = 100;
    
    % Calculate bin edges and bin centers
    bin_edges = linspace(movie_end + 1, phone_end, bins + 1); % X bins -> X+1 edges

    % Count occurrences in each bin
    SW_counts = histcounts(SW_t, bin_edges);
    
    % Initialize counter
    counter = 0;
    
    % Loop through lags
    for lag = lags
        
        % Update counter
        counter = counter + 1;
        
        if lag < 0
            SW_counts_shifted1 = SW_counts((1+abs(lag)):bins);
            SW_counts_shifted2 = SW_counts(1:(bins-abs(lag)));
        elseif lag > 0
            SW_counts_shifted1 = SW_counts(1:(bins-lag));
            SW_counts_shifted2 = SW_counts((1+lag):bins);
        else
            SW_counts_shifted1 = SW_counts;
            SW_counts_shifted2 = SW_counts;
        end
        
        % Calculate correlation coefficient
        % [rho, pval] = corr(SW_counts_shifted1', SW_counts_shifted2', 'type', 'Pearson');
        [rho, pval] = corr(SW_counts_shifted1', SW_counts_shifted2', 'type', 'Spearman');
        
        % Insert time-lagged correlation coefficients and corresponding p-values into pre-allocated matrices
        lagged_rhos(ch, counter) = rho;
        lagged_pvals(ch, counter) = pval;
        
    end
    
end

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