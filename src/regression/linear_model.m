function [reg, indx] = linear_model(features, participant, indx, reg)
%% Run GLM
%
% **Usage:** [model] = linear_model(all_eeg,epoch_window)
%
% Input(s):
%   - all_eeg = all EEG structs
%   - epoch_window = epoch window
%
% Output(s):
%   - model = LIMO model
%
[x_1] =  create_design_matrix_model(features.density,features.amplitude);
Y_1 = features.rate;

%     figure; imagesc(x_1);
disp('train mod 1')
model = {};
for current_electrode = 1:size(Y_1, 1) 
    Y_now = squeeze(Y_1(current_electrode,:,:));
    x_now = squeeze(x_1(current_electrode,:,:));
    Y_now(any(isnan(x_1(current_electrode,:,:)),3)) = [];
    x_now(any(isnan(x_1(current_electrode,:,:)),3), :) = [];
    model{current_electrode,1} = limo_glm(Y_now', x_now, 3, 0, 0, 'OLS', 'Time', 0, size(Y_1,2));
end

reg{indx, 1} = participant;
reg{indx, 2} = model;
reg{indx, 3} = x_1;
indx = indx + 1;
end