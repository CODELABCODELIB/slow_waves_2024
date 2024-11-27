function [mask, cluster_p, one_sample] = t_test_linear_mod(model, model_num, path)
%% perform LIMO level 2 one sample t-test on the betas and MCC 
%
% **Usage:** [mask, cluster_p, one_sample] = t_test_linear_mod(model, model_num, path)
%
% Input(s):
%   - model (cell) =  LIMO level 1 model results (shape : Subjects x num parameters)
%   - model_num = index with model results 
%   - path = save path for LIMO level 1 results
%
% Optional Input(s):
%   - num_params = number of parameters
%
% Output(s):
%   - masks = a binary matrix of significant/non-significant cells (shape : channels  x frames x parameter(s))
%   - p_vals = a matrix of cluster corrected p-values (shape : channels  x frames x parameter(s))
%   - one_sample = one sample t-test results (shape : channels  x frames [time, freq or freq-time]  x [mean value, se, df, t, p] x parameter(s))
%
% Author: Ruchella Kock, Leiden University, 2024
%
load('expected_chanlocs.mat')
load('channeighbstructmat.mat')
cd(path) 

%% prepare betas
x = model{1,2}{1,1}.betas;
n_betas = size(x, 1);
epoch_size = size(x, 2);
% Dimensions: electrodes * frames * betas * participants
betas = zeros(64, epoch_size, n_betas, size(model, 1));
for ppt = 1:size(model, 1)
    current_ppt_limo = model{ppt,model_num};
    for electrode = 1:size(current_ppt_limo, 1)
        betas(electrode, :, :, ppt) = current_ppt_limo{electrode}.betas';
    end
end
%% create limo struct for step 2
LIMO = struct();
LIMO.dir = pwd();
LIMO.Analysis = 'Time';
LIMO.Level = 2;
LIMO.data.chanlocs = expected_chanlocs;
LIMO.data.neighbouring_matrix = channeighbstructmat;
LIMO.data.data = path;
LIMO.data.data_dir = path;
LIMO.data.sampling_rate = 1000;
LIMO.design.bootstrap = 1000;
LIMO.design.tfce = 0;
LIMO.design.name = 'one sample t-test';
LIMO.design.electrode = [];
LIMO.design.X = [];
LIMO.design.method = 'Trimmed Mean';
%% Actually do the t-tests
% file save paths
LIMO_paths(size(betas,3)) = string();
% repeat t-test per parameter
for current_beta_index = 1:size(betas,3)
    current_beta = reshape((betas(:, 1, current_beta_index, :)),[size(current_ppt_limo, 1),1,size(model,1)]);
    LIMO_paths(current_beta_index) = limo_random_robust(1, current_beta, current_beta_index, LIMO);
end
%% perform MCC
significance_threshold = 0.05;
[mask, cluster_p, one_sample] = run_clustering_reg(LIMO_paths, significance_threshold, channeighbstructmat);
end 