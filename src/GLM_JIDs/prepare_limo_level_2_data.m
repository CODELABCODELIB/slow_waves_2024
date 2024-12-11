% Dimensions: electrodes * frames * betas * participants
input_beh = zeros(64, 2500, size(res, 2));
input_movie = zeros(64, 2500, size(res, 2));
for pp = 1:size(res, 2)
    taps = res(pp).taps;
    for chan = 1:62
        jid_behavior = taps2JID([res(pp).behavior_sws{chan,:}]);
        jid_movie = taps2JID([res(pp).movie_sws{chan,:}]);

        input_beh(chan, :, pp) = reshape(jid_behavior,2500,1);
        input_movie(chan, :, pp) = reshape(jid_movie,2500,1);
    end
end
%% remove empty bins
% sel_idxs = zeros(size(input1,1),size(input1,2));
% for chan=1:64
%     sel_idx = [std(input1(chan,:,:),[],3)>0 & std(input2(chan,:,:),[],3)>0];
%     input2(~sel_idx,:) = NaN;
%     input1(~sel_idx,:) = NaN;
%     sel_idxs(chan,:) = sel_idx;
% end
range = quantile([std(input_beh,[],3),std(input_movie,[],3)], [0.5], 'all');
not_sel_idx = std(input_beh,[],3)<=range | std(input_movie,[],3)<=range;
tmp_input_beh = input_beh(1:62,~any(not_sel_idx(1:62,:),1),:)+0.000001;
tmp_input_movie = input_movie(1:62,~any(not_sel_idx(1:62,:),1),:)+0.000001;
%% run ttest model
linear_model_save_path = '/home/ruchella/slow_waves_2023/data/GLM_movie_vs_behavior';
[mask, cluster_p, one_sample] = paired_t_test_movie_vs_phone(tmp_input_beh(1:62,:,:),tmp_input_movie(1:62,:,:),linear_model_save_path);
load(fullfile(linear_model_save_path, sprintf('paired_samples_ttest_parameter_%d.mat', 1)), 'paired_samples');
%% reconstruct
reconstructed_mask = nan(62,2500);
reconstructed_paired = nan(62,2500,size(paired_samples,3));
% sel_idx = std(input1,[],3)>range | std(input2,[],3)>range;
reconstructed_mask(:,~any(not_sel_idx(1:62,:))) = mask;
reconstructed_mask(reconstructed_mask == 0) = NaN;
reconstructed_mask(reconstructed_mask > 1) = 1;
reconstructed_paired(:,~any(not_sel_idx(1:62,:)),:) = paired_samples;
%% plot results
for n=1:10:60
    h=figure;
    tiledlayout(2,10);
    for chan=n:n+9
        nexttile;
        plot_jid(reshape(squeeze(reconstructed_paired(chan,:,1)).*reconstructed_mask(chan,:),50,50))
        colorbar;
        clim([-0.1,0.1])
        title(sprintf('Mean E %d',chan))
    end
    for chan=n:n+9
        nexttile;
        plot_jid(reshape(squeeze(reconstructed_paired(chan,:,4)).*reconstructed_mask(chan,:),50,50))
        colorbar;
        clim([-5,5])
        title(sprintf('T-values E %d',chan))
    end
    % for chan=n:n+9
    %     nexttile;
    %     plot_jid(reshape(squeeze(reconstructed_paired(chan,:,5)).*reconstructed_mask(chan,:),50,50))
    %     title(sprintf('p<0.05 E %d',chan))
    % end
    saveas(h, sprintf('%s/ttest_movie_vs_behavior_%d_%d.svg','/home/ruchella/slow_waves_2023/figures/movie_vs_behavior',n,n+9))
end
%% movie and behavior per channel
% med_beh = median(input_beh,3);
% med_movie = median(input_movie,3);
diff_b_m = med_beh - med_movie;
med_diff = median(diff_b_m,3);
for n=1:10:60
    h=figure;
    tiledlayout(4,10, 'TileSpacing','none');
    for chan=n:n+9
        nexttile
        plot_jid(reshape(med_beh(chan,:),50,50))
        title(sprintf('Beh E %d'),chan)
        % colorbar
        clim([0, 0.6])
    end
    for chan=n:n+9
        nexttile
        plot_jid(reshape(med_movie(chan,:),50,50))
        title(sprintf('Movie E %d'),chan)
        % colorbar
        clim([0, 0.6])
    end
    for chan=n:n+9
        nexttile
        plot_jid(reshape(med_diff(chan,:),50,50))
        title(sprintf('Diff E %d'),chan)
    end
    for chan=n:n+9
        nexttile
        plot_jid(reshape(squeeze(reconstructed_paired(chan,:,4)).*reconstructed_mask(chan,:),50,50))
        title(sprintf('T-values E %d'),chan)
    end
end
%% behavior or movie across channels per participant
for chan=1:62
    h = figure;
    tiledlayout(4,11)
    for pp=1:41
        nexttile
        plot_jid(reshape(input_beh(chan,:,pp),50,50))
    end
    nexttile;
    plot_jid(reshape(mean_diff(chan,:),50,50)); colorbar;
    nexttile;
    plot_jid(reshape(paired_samples(chan,:,1),50,50)); colorbar;
    nexttile;
    plot_jid(reshape(paired_samples(chan,:,4),50,50)); colorbar;
    sgtitle(sprintf('Behavior E %d',chan))
    saveas(h, sprintf('%s/behavior_%d.svg','/home/ruchella/slow_waves_2023/figures/movie_vs_behavior',chan))

    h= figure;
    tiledlayout(4,11)
    for pp=1:41
        nexttile
        plot_jid(reshape(input_movie(chan,:,pp),50,50))
    end
    nexttile;
    plot_jid(reshape(mean_diff(chan,:),50,50)); colorbar;
    nexttile;
    plot_jid(reshape(paired_samples(chan,:,1),50,50)); colorbar;
    nexttile;
    plot_jid(reshape(paired_samples(chan,:,4),50,50)); colorbar;
    sgtitle(sprintf('Movie E %d',chan))
    saveas(h, sprintf('%s/movie_%d.svg','/home/ruchella/slow_waves_2023/figures/movie_vs_behavior',chan))
end
%% 
mean_diff = trimmean(input_beh-input_movie,20,3);
figure; plot_jid(reshape(mean_diff(1,:),50,50))
