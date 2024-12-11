save_path = '/home/ruchella/slow_waves_2023/data';
n_elecs = 64;
%% SW jids behavior
behavior_sw_jid = cell(length(res),n_elecs);
for pp=1:size(res,2)
    for chan=1:n_elecs
        behavior_sw_jid{pp,chan} = taps2JID([res(pp).behavior_sws{chan,:}]);
    end
end
save(sprintf('%s/plot_data/behavior_sw_jid.mat',save_path), 'behavior_sw_jid', '-v7.3')
%% SW jids movie
movie_sw_jid = cell(length(res),n_elecs);
for pp=1:size(res,2)
    for chan=1:n_elecs
        movie_sw_jid{pp,chan} = taps2JID([res(pp).movie_sws{chan,:}]);
    end
end
save(sprintf('%s/plot_data/movie_sw_jid.mat',save_path), 'movie_sw_jid', '-v7.3')
%% latency JID2D
latency = cell(length(res),n_elecs);
for pp=1:size(res,2)
    taps = res(pp).taps;
    for chan =1:n_elecs
        sw_to_behavior_latency = assign_input_to_bin([res(pp).behavior_sws{chan,:}], res(pp).latency);
        pooled = cellfun(@(x) median(x,'omitnan'),sw_to_behavior_latency{chan},'UniformOutput', 0);
        latency{pp,chan} = log10(reshape([pooled{:}],50,50)+ 0.00000001);
    end
end
save(sprintf('%s/plot_data/latency.mat',save_path), 'latency', '-v7.3')
%% plot SW rate pooled
rate_jid = cell(length(res),n_elecs);
for pp=1:length(res)
    for chan =1:n_elecs
        if length([res(pp).behavior_sws{chan,:}])>3
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).rate);
            triad_lengths_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).triad_lengths);
            rate_jid = cellfun(@(x,y) sum(x, 'omitnan')/sum(y, 'omitnan'),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
            rate_jid{pp,chan} = (log10(reshape([rate_jid{:}],50,50)+ 0.00000000001));
        end
    end
end
save(sprintf('%s/plot_data/rate_jid.mat',save_path), 'rate_jid', '-v7.3')
%% plot SW post rate
mins=1;
post_rate = cell(length(res),n_elecs);
for pp=1:size(res,2)
    for chan =1:n_elecs
        if length([res(pp).behavior_sws{chan,:}])>3
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).post_rate);
            post_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
            % rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
            empty_bins = cellfun(@(x) isempty(x),taps_on_sw{chan}, 'UniformOutput',0);
            post_rate_jid(logical(cell2mat(empty_bins))) = {NaN};
            post_rate{pp,chan} = (log10(reshape([post_rate_jid{:}],50,50)+ 0.00000000001));
        end
    end
end
save(sprintf('%s/plot_data/post_rate.mat',save_path), 'post_rate', '-v7.3')
%% plot SW pre rate
mins=1;
pre_rate = cell(length(res),n_elecs);
for pp=1:size(res,2)
    for chan =1:n_elecs
        if length([res(pp).behavior_sws{chan,:}])>3
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).pre_rate);
            pre_rate_jid = cellfun(@(x) sum(x, 'omitnan')/(mins*60*1000),taps_on_sw{chan}, 'UniformOutput',0);
            pre_rate_jid(reshape([pre_rate_jid{:}] == 0, 50,50)) = {NaN};
            pre_rate{pp,chan} = (log10(reshape([pre_rate_jid{:}],50,50)+ 0.00000000001));
        end
    end
end
save(sprintf('%s/plot_data/pre_rate.mat',save_path), 'pre_rate', '-v7.3')
%% Plot JID-amplitdes
amp_jid = cell(length(res),n_elecs);
for pp=1:size(res,2)
    for chan=1:n_elecs
        taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).amplitude);
        sw_jid_amplitude = cellfun(@(x) median(x, 'omitnan'),taps_on_sw{chan}, 'UniformOutput',0);
        amp_jid{pp,chan} = reshape([sw_jid_amplitude{:}],50,50);
    end
end
save(sprintf('%s/plot_data/amp_jid.mat',save_path), 'amp_jid', '-v7.3')