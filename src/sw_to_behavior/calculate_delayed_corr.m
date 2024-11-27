function [rhos,ps] = calculate_delayed_corr(features,options)
%% calculate spearman correlation between slow wave features and rate
%
% **Usage:** [rhos,ps] = calculate_delayed_corr(features)
%
% Input(s):
%   - features =  struct with amplitudes, density and rates (from prepare_features_rate.m) 
%
% Optional Input(s)
%   - n_delays = minutes by which to shift the data;
%   - n_chans = number of electrodes;
%
%
% Output(s):
%   - rhos = struct with spearman rhos per feature
%   - ps = struct with p values per feature
%
% Author: Ruchella Kock, Leiden University, 2024
%
arguments
    features;
    options.n_delays double = 5;
    options.n_chans double = 64;
end
%% repeat the calculation for 2 features 
for feature={'amplitude', 'density'}
    % delay in minutes
    % delays prior to and after (n_delays*2) including no delay (+1)
    rho = nan(options.n_chans,(options.n_delays*2)+1);
    p = nan(options.n_chans,(options.n_delays*2)+1);
    
    % repeat the correlation with shifted data 
    for delay=1:(options.n_delays*2)+1
        % 1 to 5 is delay after
        if delay <= options.n_delays
            tmp_feature = zeros(size(features.(feature{:})));
            tmp_feature(:,1:size(tmp_feature,2)-delay+1) = features.(feature{:})(:,delay:end);
        elseif delay > options.n_delays+1
        % 6 to end is delay before
            tmp_feature = zeros(size(features.(feature{:})));
            tmp_feature(:,1+delay:end) = features.(feature{:})(:,1:end-delay);
        else
            tmp_feature = features.(feature{:});
        end
        % calculte the correlation per electrode 
        for chan=1:options.n_chans
            [rho(chan,delay),p(chan,delay)] = corr(features.rate(chan,:)',tmp_feature(chan,:)', 'Type', 'Spearman', 'rows','complete');
        end
    end
    % keep results per feature
    rhos.(feature{:}) = rho;
    ps.(feature{:}) = p;
end