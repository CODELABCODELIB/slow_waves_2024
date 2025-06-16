function [mask, cluster_p, one_sample] = paired_t_test_movie_vs_phone(input1,input2,path)
% model num: 2 (model 1) or 3 (model 3)

load('expected_chanlocs.mat')
load('channeighbstructmat.mat')
cd(path) 

channeighbstructmat = channeighbstructmat(1:62,1:62);
expected_chanlocs = expected_chanlocs(:,1:62);
nM = find_adj_matrix(50, 1);
%% create limo struct for step 2
LIMO = struct();
LIMO.dir = pwd();
LIMO.Analysis = 'Time';
LIMO.Level = 2;
LIMO.data.chanlocs = expected_chanlocs;
LIMO.data.neighbouring_matrix = nM;
LIMO.data.data = path;
LIMO.data.data_dir = path;
LIMO.data.sampling_rate = 1000;
LIMO.design.bootstrap = 1000;
LIMO.design.tfce = 0;
LIMO.design.name = 'paired samples t-test';
LIMO.design.electrode = [];
LIMO.design.X = [];
LIMO.design.method = 'Trimmed Mean';
%% NaN guard

%% Actually do the t-tests
% file save paths
% input1 = log10(input1 + 3.1463e-12);
% input2 = log10(input2 + 3.1463e-12);
LIMO_paths = limo_random_robust(3, input1, input2,1, LIMO);

%%
significance_threshold = 0.05;
[mask, cluster_p, one_sample] = run_clustering_linear(LIMO_paths, significance_threshold, channeighbstructmat);
save(sprintf('%s/mask.mat',path), 'mask')
save(sprintf('%s/cluster_p.mat',path), 'cluster_p')
end 