function population_sw_to_behavior_plots(feature_jid,Orignalchanlocs,options)
arguments
    feature_jid;
    Orignalchanlocs;
    options.color_lims = [];
    options.save_path  = [];
    options.show_title logical = 1;
end
%% plot the pooled sw rate JID
% rj = cat(3,cellfun(@(jid) log10(reshape([jid{:}],2500,1)+0.00000000001),feature_jid,'UniformOutput',false));
rj = cellfun(@(jid) reshape(jid,2500,1),feature_jid,'UniformOutput',false);
h = figure;
tiledlayout(8,8, 'TileSpacing','compact')
[sorted_idx] = sort_electrodes(Orignalchanlocs);
for chan=sorted_idx
    nexttile;
    tmp = cat(2,rj{:,chan});
    plot_jid(reshape(trimmean(tmp,20,2),50,50));
    if ~isempty(options.color_lims)
        clim(options.color_lims)
    else
        colorbar
    end
    xticks([])
    yticks([])
    box off;
    if options.show_title
        title(sprintf('E%d',chan), 'FontSize',9)
    end
end
if ~isempty(options.save_path)
    saveas(h,sprintf('%s',options.save_path))
end
end