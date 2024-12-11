function [reg, index] = linear_model(x,Y, participant, index, reg,options)
%% Run LIMO level 1 regression analysis
%
% **Usage:** [reg, indx] = linear_model(features, participant, indx, reg)
%
% Input(s):
%   - x = matrix with independent variables shape (electrodes x time [x freq] x params)
%   - y = dependent variable  (electrodes x time [x freq])
%   - participant (char array) = participant name 
%   - indx = pp number 
%   - reg = struct with linear model results 
%
% Optional Input(s)
%   - options.nb_conditions   = a vector indicating the number of conditions per factor
%   - options.nb_interactions = a vector indicating number of columns per interactions
%   - options.nb_continuous   = number of covariates
%
% Output(s):
%   - reg = struct with linear model results 
%       reg{indx, 1} = participant name;
%       reg{indx, 2} = linear model;
%       reg{indx, 3} = design matrix;
%
% Author: Ruchella Kock, Leiden University, 2024
%
arguments 
    x;
    Y;
    participant char;
    index double; 
    reg;
    options.nb_conditions = 3
    options.nb_interactions = 0;
    options.nb_continous = 0;
end
%% LIMO level 1
fprintf('train mod 1 - Sub %d\n',index)
model = cell(size(Y, 1),1);
% train model per electrode
for current_electrode = 1:size(Y, 1) 
    % select single electrode 
    Y_current = squeeze(Y(current_electrode,:,:));
    x_current = squeeze(x(current_electrode,:,:));
    % remove nans
    Y_current(any(isnan(x(current_electrode,:,:)),3)) = [];
    x_current(any(isnan(x(current_electrode,:,:)),3), :) = [];
    % perform regression
    model{current_electrode,1} = limo_glm(Y_current', x_current, options.nb_conditions, options.nb_interactions, options.nb_continous, 'OLS', 'Time', 0, size(Y,2));
end
%% save results
reg{index, 1} = participant;
reg{index, 2} = model;
reg{index, 3} = x;
index = index + 1;
end