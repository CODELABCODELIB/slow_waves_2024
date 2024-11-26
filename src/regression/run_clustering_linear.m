function [mask, cluster_p, one_sample] = run_clustering_linear(LIMO_paths, significance_threshold, channeighbstructmat)
    for current_beta = size(LIMO_paths, 2):-1:1
        one_sample_tmp = load(fullfile(LIMO_paths{current_beta}, sprintf('one_sample_ttest_parameter_%d.mat', current_beta)), 'one_sample');
        one_sample(:, :, :, current_beta) = one_sample_tmp.one_sample;
        
        load(fullfile(LIMO_paths{current_beta}, 'H0', sprintf('H0_one_sample_ttest_parameter_%d.mat', current_beta)), 'H0_one_sample');
        [mask(:, :, current_beta), cluster_p(:, :, current_beta)] = limo_cluster_correction(squeeze(one_sample(:, :, 4) .^ 2), squeeze(one_sample(:, :, 5)), squeeze(H0_one_sample(:, :, 1, :).^ 2), squeeze(H0_one_sample(:, :, 2, :)),channeighbstructmat,2,significance_threshold);
    end
end
