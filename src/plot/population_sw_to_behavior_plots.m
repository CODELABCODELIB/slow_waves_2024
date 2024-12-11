%% plot the pooled sw rate JID
rj = cat(3,cellfun(@(jid) log10(reshape([jid{:}],2500,1)+0.00000000001),rate_jid,'UniformOutput',false));
figure; 
tiledlayout(8,8, 'TileSpacing','none')
[sorted_idx] = sort_electrodes(EEG.Orignalchanlocs); 
for chan=sorted_idx
    nexttile;
    tmp = cat(2,rj{:,chan});
    plot_jid(reshape(trimmean(tmp,20,2),50,50));
    clim([-11,-3])
    % set(gca, 'visible', 'off')
end