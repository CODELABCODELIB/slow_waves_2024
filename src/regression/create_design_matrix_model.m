function [x] =  create_design_matrix_model(density,amplitude)
num_params = 2;
% initialize with size (num events, number of parameters)
x = zeros(size(density,1),size(density,2),num_params);
% continous variables
x(:,:,1) = density;
x(:,:,2) = amplitude;
% x(:,:,3) = repmat(1:size(density,2),[64,1]);
% Intercept
x(:,:,end+1) = ones(size(density,1),size(density,2),1);
end 