function [] = visualize_wave_pars2(wave_pars, chan_locs)

% Ensure the 'Topoplots' directory exists
if ~exist('Topoplots', 'dir')
    mkdir('Topoplots');
end

% Iterate through each segment
for seg = 1:length(wave_pars.segments)

    seg_dir = sprintf('Topoplots/Segment_%d', seg);
    if ~exist(seg_dir, 'dir')
        mkdir(seg_dir);
    end
    
    field_names = fieldnames(wave_pars.segments(seg));
    
    for i = 1:length(field_names)
        clf;
        field_name = field_names{i};
        
        if strcmp(field_name, 'wvspermin')
            plot_title = 'Slow-Wave Density';
            cb_label = 'min^-^1';
            par_name = 'density';
        elseif strcmp(field_name, 'p2pamp')
            plot_title = 'Peak-To-Peak Amplitude';
            cb_label = 'μV';
            par_name = 'p2pamp';
        elseif strcmp(field_name, 'dslope')
            plot_title = 'Downward Slope';
            cb_label = 'μV.s^-^1';
            par_name = 'dslope';
        else
            plot_title = 'Upward Slope';
            cb_label = 'μV.s^-^1';
            par_name = 'uslope';
        end
        
        values = wave_pars.segments(seg).(field_name);
        topoplot(values, chan_locs, 'style', 'both', 'shading', 'interp', 'plotrad', 0.85, 'headrad', 0.84);
        colormap(parula);
        clim([floor(min(values)) ceil(max(values))]);
        title([plot_title ' - Segment ' num2str(seg)],'FontSize', 18);
        cb = colorbar;
        cb.FontSize = 12;
        cb.Label.String = cb_label;
        cb.Label.FontSize = 18;
        cb.Label.Rotation = 270;
        cb.Label.Position = [4.5 cb.Label.Position(2) cb.Label.Position(3)];
        patch = findobj(gcf, 'Type', 'patch');
        set(patch, 'FaceColor', 'white', 'EdgeColor', 'black', 'EdgeAlpha', 0);
        lines = findobj(gcf, 'Type', 'line');
        set(lines(5), 'LineWidth', 3);
        set(lines(2:4), 'LineWidth', 1.5);
        set(lines(1), 'MarkerSize', 5);
        filename = sprintf('%s/topoplot_%s_segment_%d.png', seg_dir, par_name, seg);
        saveas(gcf, filename);
    end
end

end