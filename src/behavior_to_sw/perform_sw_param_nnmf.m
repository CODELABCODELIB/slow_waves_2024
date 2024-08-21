function [reconstruct,stable_basis,stable_loading] = perform_sw_param_nnmf(reshaped_jid,kept_bins, options)
arguments
    reshaped_jid;
    kept_bins
    options.repetitions_cv = 50;
    options.repetitions = 100;
end
basis_all = cell(options.repetitions,1);
loadings_all = cell(options.repetitions,1);
[~, ~, ~, test_err] = nnmf_cv(reshaped_jid', 'repetitions', options.repetitions_cv);
[best_k_overall]  = choose_best_k({test_err}, 1);
% perform nnmf multiple times
for rep = 1:options.repetitions
    [W, H] = perform_nnmf(reshaped_jid', best_k_overall);
    basis_all{rep,1} = W;
    loadings_all{rep,1} = H;
end
[stable_basis, stable_loading] = stable_nnmf(basis_all,loadings_all, 1);
stable_loading = full(stable_loading);
% reconstruct the jid bins
reconstruct = nan(50*50,best_k_overall);
for k=1:best_k_overall
    reconstruct(kept_bins,k) = stable_loading(k,:);
end
end