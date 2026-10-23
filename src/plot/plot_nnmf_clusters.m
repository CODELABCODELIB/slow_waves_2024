function [prototypes,labels] = plot_nnmf_clusters(all_jids,all_maps,chanlocs,options)
%% Cluster the NNMF meta-JIDs across the population and plot the clusters
%
% **Usage:**
%   - [prototypes,labels] = plot_nnmf_clusters(all_jids,all_maps,chanlocs)
%   - plot_nnmf_clusters(...,'n_clus',4,'condition','phone','save_path','mydir')
%
%  Input(s):
%   - all_jids = 2500 x n meta-JIDs (reconstruct_all_chans of all participants)
%   - all_maps = channels x n meta-locations (stable_basis_all_chans of all participants)
%   - chanlocs = channel locations of the channels in all_maps
%
%  Optional Input(s):
%   - n_clus (Default : 2) = number of k-means clusters
%   - condition (Default : 'movie') = name used in the file names
%   - save_path (Default : current directory) = folder for the figures and clusters_<condition>.mat
%   - numreps (Default : 1000) = number of k-means repetitions (lowest error is kept)
%   - clim (Default : [0 0.7]) = color limits of the meta-location topographies
%
%  Output(s):
%   - prototypes = n_clus x 2500 cluster centroids (meta-JIDs)
%   - labels = cluster label per meta-JID
%   Saves prototype_<condition>_<k>.svg (centroid JID), cluster_jid_<condition>_<k>.svg
%   (20% trimmed mean meta-location) and clusters_<condition>.mat.
%
% Same analysis as the 'movie and phone clusters' section of plot_playground.m.
%
% Author: R.M.D. Kock, Leiden University, 2026
arguments
    all_jids;
    all_maps;
    chanlocs;
    options.n_clus = 2;
    options.condition char = 'movie';
    options.save_path char = '.';
    options.numreps = 1000;
    options.clim = [0 0.7];
end
% kmeans drops meta-JIDs that contain NaN (bins removed before NNMF); set them to 0
nan_jids = any(isnan(all_jids),1);
if any(nan_jids)
    fprintf('%s: %d/%d meta-JIDs contain NaN bins, set to 0 for clustering\n', ...
        options.condition, sum(nan_jids), numel(nan_jids));
    all_jids(isnan(all_jids)) = 0;
end
[prototypes,labels] = cluster(all_jids', 'modkmeans', 0, 'n_clus', options.n_clus, 'numreps', options.numreps);
for clus=1:size(prototypes,1)
    h = figure;
    plot_jid(reshape(prototypes(clus,:),50,50));
    axis square;
    title(sprintf('%s cluster %d (n=%d)', options.condition, clus, sum(labels==clus)))
    saveas(h,sprintf('%s/prototype_%s_%d.svg',options.save_path, options.condition, clus))
    close(h)

    h = figure;
    mean_map = trimmean(all_maps(:, labels==clus),20,2);
    topoplot(mean_map,chanlocs, 'electrodes', 'off', 'style', 'map');
    colormap('parula')
    clim(options.clim)
    saveas(h,sprintf('%s/cluster_jid_%s_%d.svg',options.save_path, options.condition, clus))
    close(h)
end
save(sprintf('%s/clusters_%s.mat',options.save_path, options.condition), 'prototypes', 'labels', 'all_jids', 'all_maps')
end
