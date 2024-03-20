% Load the data
load('top10_filtered_results.mat');

% Compute wave parameters
wave_pars = compute_wave_pars(top10_filtered_results, 1000);

%%

% Extract parameters into separate vectors
wvspermin = [wave_pars.wvspermin];
p2pamp = [wave_pars.p2pamp];
dslope = [wave_pars.dslope];
uslope = [wave_pars.uslope];

% Concatenate parameters into a matrix (and transpose)
data_matrix = [wvspermin; p2pamp; dslope; uslope]';

% Calculate Pearson correlation matrix
corr_matrix = corr(data_matrix);

% Define the labels for the parameters
parameter_labels = {'Slow-Wave Density', 'Peak-To-Peak Amplitude', 'Downward Slope', 'Upward Slope'};

% Display the correlation matrix as an image
imagesc(corr_matrix);

% Add color bar to indicate the correlation values
colorbar;

% Set axis range to include all data
axis square;

% Set the labels for the X-axis and Y-axis at the appropriate tick marks
set(gca, 'XTick', 1:length(parameter_labels), 'XTickLabel', parameter_labels);
set(gca, 'YTick', 1:length(parameter_labels), 'YTickLabel', parameter_labels);

% Improve readability
xtickangle(45); % Rotate X-axis labels for better readability
ylabel('Parameters');
xlabel('Parameters');
title('Correlation Matrix');

% Adjust the colormap
colormap jet;

%%

% Scatter plot for the correlation between 'wvspermin' and 'p2pamp'
figure;
scatter(wvspermin, p2pamp, 'filled');
xlabel('Slow-Wave Density (wvspermin)');
ylabel('Peak-To-Peak Amplitude (p2pamp)');
title('Scatter Plot of Slow-Wave Density vs. Peak-To-Peak Amplitude');
grid on;
