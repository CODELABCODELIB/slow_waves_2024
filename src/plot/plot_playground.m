save_path = '/home/ruchella/slow_waves_2023/figures';
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% plot res %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot topoplots with SW params
figure;
tiledlayout(1,3)
%amplitude
nexttile;
plot_jid([jid_amp{chan}]);
colorbar;
clim([quantile(reshape([jid_amp{chan}],2500,1), [0.25,0.75])])
title(sprintf('E %d - amplitude',chan))
%upward slope
nexttile;
plot_jid([jid_upslp{chan}]);
colorbar;
clim([quantile(reshape([jid_upslp{chan}],2500,1), [0.25,0.75])])
title(sprintf('E %d - upward slope',chan))
%downward slope
nexttile;
plot_jid([jid_dnslp{chan}]);
colorbar;
clim([quantile(reshape([jid_dnslp{chan}],2500,1), [0.25,0.75])])
title(sprintf('E %d - downward slope',chan))
%% prepare JID param data for plotting
param = 'density';
jid_amp = jid_density;
reshaped_jid = cellfun(@(JID) reshape(JID,2500,1) ,jid_amp,'UniformOutput' ,false);
reshaped_jid = [reshaped_jid{:}];
reshaped_jid(isnan(reshaped_jid)) = [];
lims = round(quantile(reshaped_jid, [0.10, 0.90]));
%% plot jid param per channel
for chan=1:64
    h = figure;
    plot_jid([jid_amp{chan}]);
    colorbar;
    clim([quantile(reshape([jid_amp{chan}],2500,1), [0.25,0.75])])
    title(sprintf('E %d',chan))
    set(gca, 'fontsize', 18)
    saveas(h,sprintf('%s/jid_amp/jid_%s_E_%d',figures_save_path,param,chan))
end
%% plot all channels together
h = figure;
tiledlayout(8,8, "TileSpacing","none", "Padding","compact")
for chan=1:64
    nexttile
    plot_jid([jid_amp{chan}]);
    % colorbar;
    clim([quantile(reshape([jid_amp{chan}],2500,1), [0.25,0.75])])
    clim(lims)
    set(gca,'Visible', 'off')
    % title(sprintf('E %d',chan))
    % set(gca, 'fontsize', 18)
    saveas(h,sprintf('%s/jid_amp/jid_%s_all_E_common_axes',figures_save_path,param))
end
%% median JID per channel
med_amp_per_e = cellfun(@(jid) median(jid,'all', 'omitnan'),jid_amp,'UniformOutput',false);
figure;
topoplot([med_amp_per_e{1:62}],EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');

%% plot distribution of jid params
figure;
tiledlayout(1,2)
nexttile;
histogram([reshaped_jid(:)])
title('original')
xlim([10,150])
nexttile;
histogram(log10([reshaped_jid(:)])+ abs(min(log10(reshaped_jid), [],'all')),100)
xlim([15,25])
title('log10')
%% plot nnmf input matrix
figure; imagesc(reshaped_jid)
colorbar;
set(gca, 'fontsize',18)
xlabel('Electrodes')
ylabel('Bins')
%% plot nnmf results
h = figure;
best_k_overall = size(reconstruct,2);
tiledlayout(best_k_overall,2)
for k=1:best_k_overall
    nexttile;
    plot_jid(reshape(reconstruct(:,k),50,50))
    % clim([0 2])
    colorbar;
    set(gca, 'fontsize', 18)
    nexttile;
    topoplot(stable_basis(1:62,k),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
    clim([0 1.5])
    colorbar;
    set(gca, 'fontsize', 18)
end
%% plot nnmf results all subjects
for pp=1:41
    h = figure;
    best_k_overall = size(res(pp).reconstruct_amp,2);
    tiledlayout(best_k_overall,2)
    for k=1:best_k_overall
        nexttile;
        plot_jid(reshape(res(pp).reconstruct_amp(:,k),50,50))
        clim([0 2])
        colorbar;
        set(gca, 'fontsize', 18)
        nexttile;
        topoplot(res(pp).stable_basis_amp(1:62,k),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
        clim([0 1.5])
        colorbar;
        set(gca, 'fontsize', 18)
    end
    % saveas(h,sprintf('%s/jid_nnmf/jid_amp_nnmf_%s.svg',save_path,pp))
end
%% plot nnmf results delay
h = figure;
best_k_overall = size(reconstruct,2);
tiledlayout(best_k_overall,2)
for k=1:best_k_overall
    nexttile;
    plot_jid(reshape(reconstruct(:,k),50,50))
    colorbar;
    set(gca, 'fontsize', 18)
    nexttile;
    plot([-11:11],stable_basis(:,k))
    axis square;
    set(gca, 'fontsize', 18)
end
%% plot nnmf results delay all participants
chan = 16;
for pp=1:41
    load(sprintf('/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/jid_amp_delay_nnmf_0_to_10/reconstruct_%d.mat',pp))
    load(sprintf('/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/jid_amp_delay_nnmf_0_to_10/stable_basis_%d.mat',pp))
    stable_basis = stable_basis_all_chans{chan};
    reconstruct = reconstruct_all_chans{chan};
    h = figure;
    best_k_overall = size(reconstruct,2);
    tiledlayout(best_k_overall,2)
    for k=1:best_k_overall
        nexttile;
        plot_jid(reshape(reconstruct(:,k),50,50))
        colorbar;
        set(gca, 'fontsize', 18)
        nexttile;
        plot([-11:11],stable_basis(:,k))
        axis square;
        set(gca, 'fontsize', 18)
    end
end
%% plot nnmf population clusters
h= figure;
tiledlayout(4,size(prototypes,2))
for n_map=1:size(prototypes,2)
    nexttile;
    topoplot(prototypes(1:62,n_map),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
    clim([0, 0.2])
end
for n_map=1:size(prototypes,2)
    tmp = all_jids(:,labels==n_map);
    nexttile;
    plot_jid(reshape(tmp(:,1),[50,50]))
    clim([0, 0.7])
    axis square
end
for n_map=1:size(prototypes,2)
    tmp = all_jids(:,labels==n_map);
    nexttile;
    plot_jid(reshape(tmp(:,2),[50,50]))
    clim([0, 0.7])
    axis square
end
for n_map=1:size(prototypes,2)
    tmp = all_jids(:,labels==n_map);
    nexttile;
    plot_jid(reshape(tmp(:,3),[50,50]))
    clim([0, 0.7])
    axis square
end
colorbar;
colormap('jet')
% saveas(h,sprintf('%s/jid_nnmf/prototypes.svg',save_path))
%% plot the clustered JIDs
all_jids = cat(2,res.reconstruct);
for n_map=1:size(prototypes,2)
    tmp = all_jids(:,labels==n_map);
    h = figure;
    tiledlayout(3,ceil(size(tmp,2)/3), 'TileSpacing','none')
    for i=1:size(tmp,2)
        nexttile;
        plot_jid(reshape(tmp(:,i),[50,50]))
        clim([0,0.7])
        axis square;
    end
    % saveas(h,sprintf('%s/jid_nnmf/jid_amp_nnmf_clus_%d.svg',save_path,n_map))
    % plot the maps
    tmp = all_maps(:,labels==n_map);
    h = figure;
    tiledlayout(3,ceil(size(tmp,2)/3))
    for i=1:size(tmp,2)
        nexttile;
        topoplot(tmp(1:62,i),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
        clim([0,1])
    end
    % saveas(h,sprintf('%s/jid_nnmf/topoplots_nnmf_clus_%d.svg',save_path,n_map))
end
%% cluster behavior and explore the relevant maps
for n_clus=2:5
    [prototypes,labels] = cluster(all_jids', 'modkmeans', 0, 'n_clus',n_clus);
    figure;
    tiledlayout(1,size(prototypes,1));
    for clus=1:size(prototypes,1)
        nexttile;
        plot_jid(reshape(prototypes(clus,:),50,50));
        axis square;
    end

    for clus=1:size(prototypes,1)
        tmp = all_maps(:, labels==clus);
        figure;
        tiledlayout(5,ceil(size(tmp,2)/5)+1, 'TileSpacing','none');
        nexttile;
        plot_jid(reshape(prototypes(clus,:),50,50));
        axis square;
        for pp=1:size(tmp,2)
            nexttile;
            topoplot(tmp(1:62,pp),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
            clim([0,1])
        end
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%% plot basic sw features %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot single trials
chan=1;
for wave = 1:10;
    figure;
    plot(twa_results.channels(chan).negzx{wave}:twa_results.channels(chan).wvend{wave},EEG_refilter.data(chan,twa_results.channels(chan).negzx{wave}:twa_results.channels(chan).wvend{wave}));
    xline(twa_results.channels(chan).maxnegpk{wave}, 'r'); yline(twa_results.channels(chan).maxnegpkamp{wave}, 'r')
    xline(twa_results.channels(chan).maxpospk{wave}); yline(twa_results.channels(chan).maxpospkamp{wave})
end
%% plot erp
% maxnegpk = cell2mat(twa_results.channels(1).maxnegpk);
% [EEG_taps_ch1] = add_events(EEG_taps,maxnegpk,length(maxnegpk),'maxnegpk');
% [EEG_epoched_ch1, indices] = pop_epoch(EEG_taps_ch1, {'maxnegpk'},[-2 2]);
chan=19;
[epochedvals] = getepocheddata(EEG_refilter.data(chan,:), cell2mat(twa_results.channels(chan).negzx), [-2000,2000]);
figure; plot(trimmean(epochedvals,20,1));
title(sprintf('E %d',chan))
%% plot density
density = calculate_density(refilter.channels);
h= figure; topoplot(density(1:62),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
title('Density')
clim([round(min(density)),round(max(density))])
colormap parula; colorbar;
saveas(h,sprintf('%s/density_total_%s.svg',save_path,subject))
% %% plot density per min;
% [densities] = calculate_density_per_dur(twa_results.channels,length(EEG.times));
% density_min = [densities.med];
% h = figure; topoplot(density_min(1:62),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
% title('Density per min')
% clim([round(min(density_min)),round(max(density_min))])
% colormap parula; colorbar;
% saveas(h,sprintf('%s/density_per_min_%s.svg',save_path,subject))
%% plot p2p amp
[amp] = calculate_p2p_amplitude(refilter.channels);
h = figure; topoplot(amp(1:60),EEG.chanlocs(1:60), 'electrodes', 'off', 'style', 'map');
title('Peak-to-peak amplitude')
clim([round(min(amp(1:60))),round(max(amp(1:60)))])
colormap parula; colorbar;
saveas(h,sprintf('%s/median_amplitude_%s.svg',save_path,subject))
%% plot downward slope
[dnslp] = calculate_slope(twa_results.channels, 'sel_field',"mxdnslp");
h = figure; topoplot(dnslp(1:60),EEG.chanlocs(1:60), 'electrodes', 'off', 'style', 'map');
title('Downward slope')
clim([round(min(dnslp(1:60))),round(max(dnslp(1:60)))])
colormap parula; colorbar;
saveas(h,sprintf('%s/median_downward_slope_%s.svg',save_path,subject))
%% plot upward slope
[upslp] = calculate_slope(twa_results.channels, 'sel_field',"mxupslp");
h=figure; topoplot(upslp(1:60),EEG.chanlocs(1:60), 'electrodes', 'off', 'style', 'map');
title('Upward slope')
clim([round(min(upslp(1:60))),round(max(upslp(1:60)))])
colormap parula; colorbar;
saveas(h,sprintf('%s/median_upward_slope_%s.svg',save_path,subject))
%% Timing of all the waves
% start_times = double([twa_results.channels(1).negzx{:}]);
start_times = [twa_results.channels.negzx];
start_times = cell2mat(start_times);
recording_times = zeros(1,length(EEG_refilter.times));
recording_times(start_times) = 1;
figure;
imagesc(recording_times);
colorbar parula;
%% plot SW rate per channel
for chan=1:62
    tmp = zeros(1,max([refilter.channels(chan).negzx{:}]));
    tmp([refilter.channels(chan).negzx{:}]) = 1;
    figure;
    plot(tmp)
end
%% plot SW ITIs
for chan=1:4
    figure;
    histogram(diff([refilter.channels(chan).negzx{:}]))
end
%% plot SW Jids
for chan=1:4
    jid = taps2JID([refilter.channels(chan).negzx{:}]);
    figure;
    plot_jid(jid);
end
%% plot SW rate all channels
max_all = max(cell2mat(cellfun(@(x) max(cell2mat(x)),{refilter.channels.negzx},'UniformOutput',false)));
tmp = zeros(max_all,64);
for chan=1:63
    tmp([refilter.channels(chan).negzx{:}],chan) = 1;
end
figure;
imagesc(tmp)
%% plot behavior during SWtriad
for bin = 1:1136
    % bin = randi(size(selected_waves,2));
    tmp = selected_waves{chan,bin};
    if ~isempty(tmp) && length(tmp) > 3
        jid_behavior = taps2JID(tmp);

        h= figure;
        tiledlayout(1,2)
        nexttile;
        plot_jid(jid_behavior);
        axis square;
        title(sprintf('%d triad - size : %d',bin, length(tmp)))

        nexttile;
        input1 = num2cell(nan(1,length([refilter.channels(chan).maxnegpk{:}])));
        input1{1,bin} = 1;
        JID = assign_input_to_bin([refilter.channels(chan).maxnegpk{:}],input1);
        JID = cell2mat(cellfun(@(x) sum(~isempty(x) & ~isnan(x)) ,JID{chan} ,'UniformOutput' ,false));
        plot_jid(JID);

        set(gca, 'FontSize',18)
        colormap('parula')
        saveas(h, sprintf('%s/chan_%d_triad_%d.svg',save_path,chan,bin))
    end
end