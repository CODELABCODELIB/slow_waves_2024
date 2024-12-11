function [x] = create_design_matrix_ANCOVA(sleep_metrics,length_Y, options)
%% create design matrix for the regression 
%
% **Usage:** [x] =  create_design_matrix_model(density,amplitude)
%
% Input(s):
%   - density = slow waves frequency over time_win duration 
%   - amplitude = median slow waves amplitude over time_win duration
%
% Optional Input(s):
%   - num_params = number of parameters
%
% Output(s):
%   - x = Matrix (Shape : electrodes x time windows x num params)
%
% Author: Ruchella Kock, Leiden University, 2024
%
arguments 
    sleep_metrics;
    length_Y;
    options.num_params = 2;
end
% initialize with size (num events, number of parameters)
x = zeros(length_Y,options.num_params);
% continous variables / covariates
% sleep duration (constant)
x(:,1) = zscore(repmat(sleep_metrics.sleep_durations(end), [length_Y,1]));
% time since awake (constant)
time_since_awake = zeros(1,length_Y);
time_since_awake(1) = sleep_metrics.time_awake_posix; 
for i=2:length_Y
    time_since_awake(i) = time_since_awake(i-1) + 60; 
end
x(:,2) = zscore(time_since_awake);
% Intercept
x(:,end+1) = ones(length_Y,1);
end 