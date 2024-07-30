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
    best_k_overall = size(r(pp).reconstruct_amp,2);
    tiledlayout(best_k_overall,2)
    for k=1:best_k_overall
        nexttile;
        plot_jid(reshape(r(pp).reconstruct_amp(:,k),50,50))
        clim([0 2])
        colorbar;
        set(gca, 'fontsize', 18)
        nexttile;
        topoplot(r(pp).stable_basis_amp(1:62,k),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
        clim([0 1.5])
        colorbar;
        set(gca, 'fontsize', 18)
    end
    saveas(h,sprintf('%s/jid_nnmf/jid_amp_nnmf_%s.svg',save_path,pp))
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
    plot([-5:5],stable_basis(:,k))
    axis square;
    set(gca, 'fontsize', 18)
end
%% plot nnmf clusters
figure; 
tiledlayout(1,size(prototypes,2))
for n_map=1:size(prototypes,2)
    nexttile;
    topoplot(prototypes(1:62,n_map),EEG.chanlocs(1:62), 'electrodes', 'off', 'style', 'map');
    clim([-0.3 0.3])
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