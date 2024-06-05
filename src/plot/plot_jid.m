function [h] = plot_jid(jid, options)
arguments
    jid
    options.scale logical = 0;
    options.MIN_H = 1.5;
    options.MAX_H = 5;
    options.BINS = 50;
end
gridx = linspace(options.MIN_H, options.MAX_H, options.BINS);
% get the x and y coordinates of each bin
[x1, x2] = meshgrid(gridx, gridx);
x1 = x1(:);
x2 = x2(:);
xi = [x1 x2];

h = imagesc(xi(:,1), xi(:,2),jid);
% h = imagesc(xi(:,1), xi(:,2),jid, 'Interpolation', 'bilinear');
set(gca, 'YDir', 'normal')
if options.scale
    caxis([0,1.8])
end
% set nans as 0
set(h, 'AlphaData', ~isnan(jid))
box off;
colormap('jet')
% colorbar
axis square;
end