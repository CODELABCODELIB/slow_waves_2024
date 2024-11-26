function [features] = prepare_features_rate(res, pp,options)
arguments
    res;
    pp;
    options.plot logical = 0;
    options.time_win = 60000;
    options.n_chans = 64;
end
density = nan(options.n_chans,floor((res(pp).taps(end)-res(pp).taps(1))/60000));
rate = nan(options.n_chans,floor((res(pp).taps(end)-res(pp).taps(1))/60000));
amplitude = nan(options.n_chans,floor((res(pp).taps(end)-res(pp).taps(1))/60000));

for chan =1:options.n_chans
    count = 1;
    slow_waves = [res(pp).behavior_sws{chan,:}];
    taps = [res(pp).taps];
    neg_amplitudes = [res(pp).refilter.channels(chan).maxnegpkamp{:}];
    pos_amplitudes = [res(pp).refilter.channels(chan).maxpospkamp{:}];

    for i=res(pp).taps(1):options.time_win:floor((res(pp).taps(end)-res(pp).taps(1))/60000)*60000+res(pp).taps(1)
        windowed_sws = slow_waves(slow_waves>=i & slow_waves<=i+options.time_win);
        neg = neg_amplitudes(slow_waves>=i & slow_waves<=i+options.time_win);
        pos = pos_amplitudes(slow_waves>=i & slow_waves<=i+options.time_win);
        amplitudes = abs(neg-pos);
        rate(chan,count) = length(taps(taps>=i & taps<=i+options.time_win));
        if ~isempty(windowed_sws)
            density(chan,count) = length(windowed_sws);
            amplitude(chan,count) = median(amplitudes);
        end
        count = count +1;
    end
end
features.density = density;
features.amplitude = amplitude;
features.rate = rate;
%%
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