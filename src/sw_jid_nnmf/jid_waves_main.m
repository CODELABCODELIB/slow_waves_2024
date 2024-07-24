function [res] = jid_waves_main(load_data,options)
arguments
    load_data;
    options.save_results logical = 1;
    options.save_path char = '.';
    options.parameter = '';
    options.file = '';
    options.repetitions = 50;
    options.plot_res logical = 0;
    options.threshold = 0;
    options.n_bins = 50;
end
res = struct();
count = 1;
for pp=1:size(load_data,1)
    [~,res(count).phone_indexes,~,~,taps_all] = seperate_movie_phone(load_data(pp,:),'get_movie_idxs',0);
    if ~isempty(taps_all)
        res(count).refilter = load_data{count,4};
        res(count).taps = taps_all{1};
        [res(count).dt_dt_r,~] = calculate_ITI_K_ITI_K1(res(count).taps, 'shuffle', 0);
        %% select sw per triad
        [res(count).selected_waves,res(count).triad_lengths] = sw_per_triad(res(count).taps,res(count).refilter);
        %% create the jid for each slow wave parameter
        % create the jid for the p2p amp
        f = @calculate_p2p_amplitude;
        [res(count).jid_amp,res(count).amp_per_triad,res(count).not_occupied_bins] = jid_per_param(res(count).refilter.channels,res(count).selected_waves,res(count).dt_dt_r, f, 'sel_field',"maxpospkamp");
        %% perform nnmf
        [res(count).reshaped_jid_amp,res(count).kept_bins] = prepare_sw_data_for_nnmf(res(count).jid_amp,'zscore', 1, 'threshold',0.75, 'log_transform',0);
        if ~isempty(res(count).reshaped_jid_amp)
            [res(count).reconstruct,res(count).stable_basis] = perform_sw_param_nnmf(res(count).reshaped_jid_amp,res(count).kept_bins, 'repetitions_cv',50);
        end
        count = count+1;
        if options.save_results
            save(sprintf('%s/%s_res_%d',options.save_path,options.file, pp),'res')
        end
    end
end
end