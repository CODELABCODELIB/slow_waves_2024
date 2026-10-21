function [] = visualize_wave_pars(wave_pars, chan_locs, output_directory, show_figures)

if nargin < 3
    output_directory = fullfile(fileparts(mfilename('fullpath')), 'Topoplots');
end
if nargin < 4
    show_figures = false;
end
if ~exist(output_directory, 'dir')
    mkdir(output_directory);
end
dir = output_directory;
visibility = 'off';
if show_figures
    visibility = 'on';
end

field_names = fieldnames(wave_pars);

for i = 1:length(field_names)
    fig = figure('Visible', visibility, 'Color', 'white');
    figure_cleanup = onCleanup(@() close_if_hidden(fig, show_figures));
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
  
    if any(isfinite(wave_pars.(field_name)))
    values = wave_pars.(field_name);
    finite_values = values(isfinite(values));
    limits = [floor(min(finite_values)), ceil(max(finite_values))];
    if limits(1) == limits(2)
        limits(2) = limits(1) + 1;
    end
    topoplot(wave_pars.(field_name), chan_locs, 'style', 'both', 'shading', 'interp', 'plotrad', 0.85, 'headrad', 0.84, 'maplimits', limits);
    colormap(parula);
    caxis(limits);
    title(plot_title,'FontSize', 18);
    cb = colorbar;
    cb.FontSize = 12;
    cb.Label.String = cb_label;
    cb.Label.FontSize = 18;
    cb.Label.Rotation = 270;
    cb.Label.Position = [4.5 cb.Label.Position(2) cb.Label.Position(3)];
    patch = findobj(gcf, 'Type', 'patch');
    set(patch, 'FaceColor', 'white', 'EdgeColor', 'black', 'EdgeAlpha', 0);
    lines = findobj(gcf, 'Type', 'line');
    if numel(lines) >= 5
        set(lines(5), 'LineWidth', 3);
    end
    if numel(lines) >= 2
        set(lines(2:min(4,end)), 'LineWidth', 1.5);
    end
    if ~isempty(lines)
        set(lines(1), 'MarkerSize', 5);
    end
    else
        text(0.5, 0.5, 'No finite wave parameters', 'HorizontalAlignment', 'center');
        axis off;
        title(plot_title, 'FontSize', 18);
    end
    filename = sprintf('%s/topoplot_%s.png', dir, par_name);
    saveas(fig, filename);
    clear figure_cleanup;
end

end

function close_if_hidden(fig, show_figures)
if ~show_figures && isgraphics(fig)
    close(fig);
end
end
