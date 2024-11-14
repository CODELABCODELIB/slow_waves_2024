function [] = visualize_corr(coefs, max_lag, chan_locs)

% Ensure the 'Topoplots' directory exists
if ~exist('Topoplots', 'dir')
    mkdir('Topoplots');
end

dir = 'Topoplots';

% Creating lag vector
lags = -max_lag:max_lag;

% Initialize counter
counter = 0;

for lag = lags

    % Update counter
    counter = counter + 1;

    clf;

    lag_min = lag * 0.5;

    plot_title = sprintf('Slow-Wave Time Lag: %.1f min', lag_min);
    cb_label = sprintf("Spearman's Rho\n(p < .01)");
    % cb_label = sprintf("Spearman's Rho");
    % cb_label = sprintf("Pearson's R\n(p < .01)");
    % cb_label = sprintf("Pearson's R");

    topoplot(coefs(:, counter), chan_locs, 'style', 'both', 'shading', 'interp', 'plotrad', 0.85, 'headrad', 0.84);

    % Number of colors in the colormap
    n = 256; 

    % Define the blue to white to red transition
    b = [0, 0, 1]; % Blue
    w = [1, 1, 1]; % White
    r = [1, 0, 0]; % Red

    % Create the colormap
    newmap = zeros(n, 3);

    % Blue to white transition
    for i = 1:floor(n/2)
        newmap(i, :) = b + (w - b) * (i-1) / (floor(n/2) - 1);
    end

    % White to red transition
    for i = floor(n/2)+1:n
        newmap(i, :) = w + (r - w) * (i - floor(n/2) - 1) / (n - floor(n/2) - 1);
    end

    % Apply the colormap
    colormap(newmap);

    % clim([-0.40000001, 0.40000001]);

    title(plot_title,'FontSize', 18);

    cb = colorbar;
    cb.FontSize = 12;
    cb.Label.String = cb_label;
    cb.Label.FontSize = 18;
    cb.Label.Rotation = 270;
    cb.Label.Position = [5.5 cb.Label.Position(2) cb.Label.Position(3)];
    % cb.Label.Position = [4.5 cb.Label.Position(2) cb.Label.Position(3)];

    patch = findobj(gcf, 'Type', 'patch');
    set(patch, 'FaceColor', 'white', 'EdgeColor', 'black', 'EdgeAlpha', 0);
    lines = findobj(gcf, 'Type', 'line');
    set(lines(5), 'LineWidth', 3);
    set(lines(2:4), 'LineWidth', 1.5);
    set(lines(1), 'MarkerSize', 5);

    filename = sprintf('%s/topoplot_lag%d.png', dir, lag);
    saveas(gcf, filename);
    
end

end