function [h] = plot_jid(xi, jid, options)
arguments
    xi
    jid
    options.scale logical = 0;
end
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
end