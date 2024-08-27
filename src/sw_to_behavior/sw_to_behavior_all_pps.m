function [res] = sw_to_behavior_all_pps(load_data,options)
arguments
    load_data;
    options.save_results logical = 1;
    options.save_path char = '.';
    options.parameter = '';
    options.file = '';
    options.plot_res logical = 0;
end
res = struct();
count = 1;
for pp=1:size(load_data,1)
    [~,phone_indexes,~,~,taps] = seperate_movie_phone(load_data(pp,:),'get_movie_idxs',0);
    if ~isempty(phone_indexes)
        res(count).taps = taps{1};
        res(count).refilter = load_data{count,4};
    
        [res(count).rate,res(count).triad_lengths] = tap_per_sw_triad(res(count).taps,res(count).refilter,'rate');

        res(count).post_rate= tap_per_sw_triad(res(count).taps,res(count).refilter,'post_rate');

        res(count).pre_rate = tap_per_sw_triad(res(count).taps,res(count).refilter,'pre_rate');

        res(count).latency = tap_per_sw_triad(res(count).taps,res(count).refilter,'latency');

        count = count +1;
        if options.save_results
            save(sprintf('%s/%s_res_%d',options.save_path,options.file, pp),'res')
        end
    end
end
end