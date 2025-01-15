function [prototypes,labels,cluster_prototypes,cluster_labels,error] = cluster(all_prototypes,options)
%% perform kmeans clustering
%
% **Usage:**
%   - cluster(all_clusters)
%   - cluster(...[3:20])
%   - cluster(...,..., 100)
%
% Input(s):
%    all_prototypes = all the prototypes
% 
% Optional input parameter(s):
%   n_clus (default : [2:15]) = array with the number of possible clusters 
%       to form 'k' for modkmeans
%   numreps (default : 1000) = number of times to repeat modkmeans
%   
% Output(s):
%   prototypes = prototypes of best cluster
%   labels = clustering labels
%   cluster_prototypes = prototypes for all repetitions
%   cluster_labels = labels for all repetitions
%
% Requires:
%   modkmeans
%
% Author: R.M.D. Kock, Leiden University, 04/12/2023

arguments
    all_prototypes;
    options.n_clus = [2:15];
    options.numreps = 1000;
    options.modkmeans logical = 1;
end
%% cluster 
% idx = kmeans(all_clusters', n_clus);
opts.fitmeas = 'CV'; opts.optimised = 1; opts.reps = 100;
% [prototypes, labels, Res] = modkmeans(all_prototypes,options.n_clus, opts);
%% 
cluster_prototypes = {};
cluster_labels = {};
ssqs = zeros(options.numreps,1);
for rep=1:options.numreps
    if options.modkmeans
        [prototypes, labels, Res] = modkmeans(all_prototypes,options.n_clus, opts);
        ssqs(rep) = sum(Res.MSE);
    else
        [labels,prototypes, Res] = kmeans(all_prototypes,options.n_clus);
        ssqs(rep) = sum(Res);
    end
    cluster_prototypes{rep} = prototypes;
    cluster_labels{rep} = labels;
    
end
[error,idx] = min(ssqs);
prototypes = cluster_prototypes{idx};
labels = cluster_labels{idx};