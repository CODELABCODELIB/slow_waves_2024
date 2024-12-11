function [mask, cluster_p, one_sample] = run_clustering_reg(LIMO_paths, significance_threshold, channeighbstructmat)
%% MCC for each parameter
%
% **Usage:** [mask, cluster_p, one_sample] = run_clustering_reg(LIMO_paths, significance_threshold, channeighbstructmat)
%
% Input(s):
%   - LIMO_paths = save path for LIMO level 1 results
%   - significance_threshold = alpha for significance testing
%   - channeighbstructmat = neighboring channels
%
% Output(s):
%   - masks = a binary matrix of significant/non-significant cells (shape : channels  x frames x parameter(s))
%   - p_vals = a matrix of cluster corrected p-values (shape : channels  x frames x parameter(s))
%   - one_sample = one sample t-test results (shape : channels  x frames [time, freq or freq-time]  x [mean value, se, df, t, p] x parameter(s))
%
% Author: Ruchella Kock, Leiden University, 2021
%
%% load data per parameter and repeat the MCC
for current_beta = size(LIMO_paths, 2):-1:1
        % load one sample t-test results
        one_sample_tmp = load(fullfile(LIMO_paths{current_beta}, sprintf('one_sample_ttest_parameter_%d.mat', current_beta)), 'one_sample');
        one_sample(:, :, :, current_beta) = one_sample_tmp.one_sample;
        % load boot H0 values
        load(fullfile(LIMO_paths{current_beta}, 'H0', sprintf('H0_one_sample_ttest_parameter_%d.mat', current_beta)), 'H0_one_sample');
        % MCC Inputs: 
        % M = matrix of observed F values (electrodes x time [x freq])
        % P = matrix of observed p values (electrodes x time [x freq])
        % bootM = matrix of F values for data under H0 (electrodes x time [x freq] x number of boots)
        % bootP = matrix of P values for data under H0 (electrodes x time [x freq]x number of boots)
        [mask(:, :, current_beta), cluster_p(:, :, current_beta)] = limo_cluster_correction((one_sample(:, :, 4) .^ 2), (one_sample(:, :, 5)), reshape(H0_one_sample(:, :, 1, :).^ 2,64,1,1000),reshape(H0_one_sample(:, :, 2, :).^ 2,64,1,1000),channeighbstructmat,2,significance_threshold);
    end
end
end