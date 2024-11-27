function [features] = prepare_features_rate(res, pp,options)
%% calculate behavioral rate and slow wave features (amplitude and density)
%
% **Usage:** [features] = rate_sws_features(res,pp)
%                       = rate_sws_features(...,'time_win', 30000)
%
% Input(s):
%   - res = processed slow waves data (from sw_to_behavior_all_pps)
%   - pp [int] = pp number
%
% Optional Input(s)
%   - plot (Default: 0) = logical 1 plot results, 0 otherwise
%   - time_win (Default: 60000) = duration of the timewindow in millisecond
%   - n_chans (Default: 64) = number of electrodes
%
% Output(s):
%   - features = Struct with following fields (Shape : number electrodes x number of time windows)
%       density = slow waves frequency over time_win duration 
%       amplitude = median slow waves amplitude over time_win duration 
%       rate = number of taps over time_win duration 
%
% Author: Ruchella Kock, Leiden University, 2024
%
arguments
    res;
    pp;
    options.plot logical = 0;
    options.time_win = 60000;
    options.n_chans = 64;
end
% initialize variables
density = nan(options.n_chans,floor((res(pp).taps(end)-res(pp).taps(1))/60000));
rate = nan(options.n_chans,floor((res(pp).taps(end)-res(pp).taps(1))/60000));
amplitude = nan(options.n_chans,floor((res(pp).taps(end)-res(pp).taps(1))/60000));

% calculate features per electrode
for chan =1:options.n_chans
    count = 1;
    % slow waves during smartphone behavior at most negative peak index
    slow_waves = [res(pp).behavior_sws{chan,:}];
    % index of smartphone taps
    taps = [res(pp).taps];
    % select slow wave amplitudes
    neg_amplitudes = [res(pp).refilter.channels(chan).maxnegpkamp{:}];
    pos_amplitudes = [res(pp).refilter.channels(chan).maxpospkamp{:}];

    for i=res(pp).taps(1):options.time_win:floor((res(pp).taps(end)-res(pp).taps(1))/options.time_win)*options.time_win+res(pp).taps(1)
        % select slow waves within time window 
        windowed_sws = slow_waves(slow_waves>=i & slow_waves<=i+options.time_win);
        neg = neg_amplitudes(slow_waves>=i & slow_waves<=i+options.time_win);
        pos = pos_amplitudes(slow_waves>=i & slow_waves<=i+options.time_win);
        amplitudes = abs(neg-pos);
        rate(chan,count) = length(taps(taps>=i & taps<=i+options.time_win));
        % check if there were any events 
        if ~isempty(windowed_sws)
            density(chan,count) = length(windowed_sws);
            amplitude(chan,count) = median(amplitudes);
        end
        count = count +1;
    end
end
% save results in a struct 
features.density = density;
features.amplitude = amplitude;
features.rate = rate;
%% plot results , density and rate
if options.plot
    h = figure;
    n=4;
    tiledlayout(n,n, 'TileSpacing','compact')
    for chan=1:n*n
        nexttile;
        plot(density(chan,:))
        ylabel('Density')
        yyaxis right
        plot(rate(chan,:))
        % xlabel('min')
        ylabel('rate')
        box off;
        title(sprintf('Chan %d - N %d',chan, length([res(pp).behavior_sws{chan,:}])))
    end
    sgtitle(sprintf('Sub %d',pp))
    % saveas(h, sprintf('%s/sw_to_behavior/jid_sw_pp_behavior_%d.svg',figures_save_path,pp))
end
end