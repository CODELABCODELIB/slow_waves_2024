%% save data
save_path_data = '/home/ruchella/slow_waves_2023/data/regression';
%% perform LIMO level 1
reg = cell(size(res,2),3);
indx = 1;
for pp=1:size(res,2)
    [features] = prepare_features_rate(res,pp, 'plot',0);
    x =  create_design_matrix_model(features.density,features.amplitude);
    y = features.rate;
    [reg, indx] = linear_model(x,y,res(pp).pp, indx, reg);
end
save(sprintf('%s/reg.mat',save_path_data),'reg')
%% perform LIMO level 2
[mask, cluster_p, one_sample] = t_test_linear_mod(reg, 2, save_path_data);
save(sprintf('%s/mask.mat',save_path_data),'mask')
save(sprintf('%s/cluster_p.mat',save_path_data),'cluster_p')
save(sprintf('%s/one_sample.mat',save_path_data),'one_sample')