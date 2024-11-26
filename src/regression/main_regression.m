%% save data
save_path_data = '/home/ruchella/slow_waves_2023/data/regression';
%% LIMO level 1
reg = {};
for pp=1:size(res,2)
    [features] = prepare_features_rate(res,pp, 'plot',0);
    [reg, indx] = linear_model(features, res(pp).pp, pp, reg);
end
save(sprintf('%s/reg.mat',save_path_data),'reg')
%% LIMO level 2
[mask, cluster_p, one_sample] = t_test_linear_mod(reg, 2, save_path_data);
save(sprintf('%s/mask.mat',save_path_data),'mask')
save(sprintf('%s/cluster_p.mat',save_path_data),'cluster_p')
save(sprintf('%s/one_sample.mat',save_path_data),'one_sample')