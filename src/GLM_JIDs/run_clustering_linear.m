function [mask, cluster_p, paired_samples] = run_clustering_linear(LIMO_paths, significance_threshold, channeighbstructmat)
current_beta =1;
load(fullfile(LIMO_paths, sprintf('paired_samples_ttest_parameter_%d.mat', current_beta)), 'paired_samples');
% paired_samples(:, :, :, current_beta) = paired_samples;

load(fullfile(LIMO_paths, 'H0', sprintf('H0_paired_samples_ttest_parameter_%d.mat', current_beta)), 'H0_paired_samples');
[mask(:, :, current_beta), cluster_p(:, :, current_beta)] = limo_cluster_correction(squeeze(paired_samples(:, :, 4) .^ 2), squeeze(paired_samples(:, :, 5)), squeeze(H0_paired_samples(:, :, 1, :).^ 2), squeeze(H0_paired_samples(:, :, 2, :)),channeighbstructmat,2,significance_threshold);
end
