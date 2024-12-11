function [model] = linear_model(x,y,options)
%% Run LIMO level 1 regression analysis
%
% **Usage:** [reg, indx] = linear_model(features, participant, indx, reg)
%
% Input(s):
%   - x = matrix with independent variables shape (electrodes x time [x freq] x params)
%   - y = dependant variable  (electrodes x time [x freq])
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
    y;
    options.nb_conditions = 2;
    options.nb_interactions = 0;
    options.nb_continous = 3;
end
%% LIMO level 1
model = cell(size(y, 1),1);
% train model per electrode
for current_electrode = 1:size(y, 1) 
    % select single electrode 
    Y_1 = squeeze(y(current_electrode,:,:));
    % perform regression
    model{current_electrode,1} = limo_glm(Y_1', x, options.nb_conditions, options.nb_interactions, options.nb_continous, 'OLS', 'Time', 0, size(y,2));
end
end