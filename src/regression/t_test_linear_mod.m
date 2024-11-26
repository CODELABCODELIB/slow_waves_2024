function [mask, cluster_p, one_sample] = t_test_linear_mod(model, model_num, path)
% model num: 2 (model 1) or 3 (model 3)

load('expected_chanlocs.mat')
load('channeighbstructmat.mat')
cd(path) 

%% LIMO Step 2
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

for current_beta_index = 1:size(betas,3)
    current_beta = squeeze(betas(:, :, current_beta_index, :));
    LIMO_paths(current_beta_index) = limo_random_robust(1, current_beta, current_beta_index, LIMO);
end
%%
significance_threshold = 0.05;
[mask, cluster_p, one_sample] = run_clustering_linear(LIMO_paths, significance_threshold, channeighbstructmat);
end 