function [x] =  create_design_matrix_model(density,amplitude, options)
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
    density;
    amplitude;
    options.num_params = 2;
end
% initialize with size (num events, number of parameters)
x = zeros(size(density,1),size(density,2),options.num_params);
% continous variables
x(:,1) = density;
x(:,2) = amplitude;
% x(:,:,3) = repmat(1:size(density,2),[64,1]);
% Intercept
x(:,end+1) = ones(size(density,1),size(density,2),1);
end 