function Figures_postanalysis_movie(EEG,mean_vals,sig_t,range_time,real_timestamps, save_name,mean_plot_title, mean_lims, t_lims)
figure;
idx = 1;
v = VideoWriter(sprintf('%s.avi', save_name));
v.FrameRate = 30;
open(v)
% for i = [2001:10:4000 4000:6000 6000:10:8000]
for i = range_time
    tiledlayout(1,2);
%     real_timestamps = i-2000;
%     number_timestamps = real_timestamps+(size(mean_vals,2)/2);
    % topoplot
    ax1 = nexttile;
    topoplot([squeeze(mean_vals(:,i))], EEG.chanlocs , 'whitebk', 'on', 'electrodes', 'off', 'maplimits', mean_lims, 'colormap', colormap('jet'));
    title(mean_plot_title);
    freezeColors;
    colorbar(ax1, 'Location', 'eastoutside', 'limits', mean_lims);

    % topoplot
    hold off;
    ax2 = nexttile;
    topoplot([squeeze(sig_t(:,i))], EEG.chanlocs, 'whitebk', 'on', 'electrodes', 'off', 'maplimits', t_lims, 'colormap', colormap('jet'));
    title([{'T-values'},{'(MCC, p<0.05)'}]);
    %colorbar
    hold on 
    ax2 = colorbar('Location', 'eastoutside', 'limits', t_lims);
    
    sgtitle(sprintf('%d ms', real_timestamps(idx)), 'FontSize', 40);
    set(gcf,'color','w');
    M =getframe(gcf);
    writeVideo(v,M);
    clf;
    idx = idx + 1;
end
close(v);
end