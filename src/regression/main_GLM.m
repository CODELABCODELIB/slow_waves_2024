%% save data
save_path_data = '/home/ruchella/slow_waves_2023/data/GLM';
%%
for pp=1:size(res,2)
    [features] = prepare_features_rate(res,pp, 'plot',0);
    rhos{pp} = calculate_delayed_corr(features);
    % [reg, indx] = linear_model(features, res(pp).pp, pp, reg);
    % density spearman correlation
    h = figure;
    tiledlayout(2,6)
    maplimits = [-max(round(quantile(rhos{pp}.density, [0, 1], 'all'),2)),max(round(quantile(rhos{pp}.density, [0, 1], 'all'),2))];
    for delay=1:11
        nexttile;
        if ~all(isnan(rhos{pp}.density(1:62,delay)))
            topoplot(rhos{pp}.density(1:62,delay),EEG.chanlocs(1:62), 'maplimits',maplimits, 'electrodes', 'off', 'style', 'map');
            colorbar;
        end

        if delay <= 5
            title(sprintf('%d delay',delay))
        elseif delay > 6
            title(sprintf('-%d delay',delay-6))
        else
            title('0 delay')
        end
    end
    sgtitle(sprintf('Sub %d - Density',pp))
    saveas(h,sprintf('%s/dec_rerun/corr_delays/density_spearman_rho_%d.svg',figures_save_path,pp))

    % amplitude spearman correlation
    h = figure;
    tiledlayout(2,6)
    maplimits = [-max(round(quantile(rhos{pp}.amplitude, [0, 1], 'all'),2)),max(round(quantile(rhos{pp}.amplitude, [0, 1], 'all'),2))];
    for delay=1:11
        nexttile;
        if ~all(isnan(rhos{pp}.amplitude(1:62,delay)))
            topoplot(rhos{pp}.amplitude(1:62,delay),EEG.chanlocs(1:62), 'maplimits',maplimits,'electrodes', 'off', 'style', 'map');
            colorbar;
        end

        if delay <= 5
            title(sprintf('%d delay',delay))
        elseif delay > 6
            title(sprintf('-%d delay',delay-6))
        else
            title('0 delay')
        end
    end
    sgtitle(sprintf('Sub %d - Amplitude',pp))
    saveas(h,sprintf('%s/dec_rerun/corr_delays/amplitude_spearman_rho_%d.svg',figures_save_path,pp))
end