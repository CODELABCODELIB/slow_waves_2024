% Dimensions: electrodes * frames * betas * participants
input1 = zeros(64, 2500, size(res, 2));
input2 = zeros(64, 2500, size(res, 2));
for pp = 1:size(res, 2)
    taps = res(pp).taps;
    for chan = 1:62
        jid_behavior = taps2JID([res(pp).behavior_sws{chan,:}]);

        slow_waves_start = [res(pp).refilter.channels(chan).maxnegpk{:}];
        movie_sws = slow_waves_start(slow_waves_start<=taps(1));
        jid_movie = taps2JID(movie_sws);

        input1(chan, :, pp) = reshape(jid_behavior,2500,1);
        input2(chan, :, pp) = reshape(jid_movie,2500,1);
    end
end
%% run ttest model
linear_model_save_path = '/home/ruchella/slow_waves_2023/data/GLM_movie_vs_behavior';
[mask, cluster_p, one_sample] = paired_t_test_movie_vs_phone(input1,input2,linear_model_save_path);
load(fullfile(linear_model_save_path, sprintf('paired_samples_ttest_parameter_%d.mat', 1)), 'paired_samples');
%% plot results
for n=1:10:60
    h=figure;
    tiledlayout(3,10);
    for chan=n:n+9
        nexttile;
        plot_jid(reshape(paired_samples(chan,:,1),50,50))
        colorbar;
        title(sprintf('Mean E %d',chan))
    end
    for chan=n:n+9
        nexttile;
        plot_jid(reshape(paired_samples(chan,:,4),50,50))
        colorbar;
        title(sprintf('T-values E %d',chan))
    end
    for chan=n:n+9
        nexttile;
        plot_jid(reshape(paired_samples(chan,:,5),50,50)<0.05)
        title(sprintf('p<0.05 E %d',chan))
    end
    saveas(h, sprintf('%s/ttest_movie_vs_behavior_%d_%d.svg','/home/ruchella/slow_waves_2023/figures/movie_vs_behavior',n,n+9))
end
%% behavior or movie across channels per participant
for chan=1:62
    h = figure;
    tiledlayout(4,11)
    for pp=1:41
        nexttile
        plot_jid(reshape(input1(chan,:,pp),50,50))
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
        plot_jid(reshape(input2(chan,:,pp),50,50))
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
mean_diff = trimmean(input1-input2,20,3);
figure; plot_jid(reshape(mean_diff(1,:),50,50))
