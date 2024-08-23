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
    options.get_jid_amp logical = 1;
    options.get_jid_density logical = 0;
    options.get_jid_upslp logical = 0;
    options.get_jid_dnslp logical = 0;
end
res = struct();
count = 1;
for pp=1:size(load_data,1)
    [~,phone_indexes,~,~,taps_all] = seperate_movie_phone(load_data(pp,:),'get_movie_idxs',0);
    if ~isempty(taps_all)
        res(count).phone_indexes = phone_indexes;
        res(count).refilter = load_data{count,4};
        res(count).taps = taps_all{1};
        [res(count).dt_dt_r,~] = calculate_ITI_K_ITI_K1(res(count).taps, 'shuffle', 0);
        %% select sw per triad
        [res(count).selected_waves,res(count).triad_lengths] = sw_per_triad(res(count).taps,res(count).refilter);
        % create the jid for each slow wave parameter
        %% create the jid and perform NNMF for the p2p amp
        if options.get_jid_amp
            f = @calculate_p2p_amplitude;
            [res(count).jid_amp,res(count).amp_per_triad,res(count).not_occupied_bins] = jid_per_param(res(count).refilter.channels,res(count).selected_waves,res(count).dt_dt_r, f, 'sel_field',"maxpospkamp");
            % perform nnmf for jid amp
            [res(count).reshaped_jid_amp,res(count).kept_bins] = prepare_sw_data_for_nnmf(res(count).jid_amp,'zscore', 1, 'threshold',0.75, 'log_transform',0);
            if ~isempty(res(count).reshaped_jid_amp)
                [res(count).reconstruct_amp,res(count).stable_basis_amp] = perform_sw_param_nnmf(res(count).reshaped_jid_amp,res(count).kept_bins, 'repetitions_cv',50);
            end
        end
        %% create the jid and perform NNMF for the density
        if options.get_jid_density
            [res(count).jid_density,res(count).density_per_triad] = jid_per_param(res(count).refilter.channels,res(count).selected_waves,res(count).dt_dt_r, [], res(count).triad_lengths);
            [res(count).reshaped_jid_density,res(count).kept_bins_density] = prepare_sw_data_for_nnmf(jid_density,'threshold',0, 'log_transform',0);
            % perform nnmf for jid density
            if ~isempty(reshaped_jid_density)
                [res(count).reconstruct_density,res(count).stable_basis_density] = perform_sw_param_nnmf(reshaped_jid_density,kept_bins, 'repetitions_cv',2);
            end
        end
        %% create the jid and perform NNMFfor the upward slopes
        if options.get_jid_upslp
            % upward slopes JID
            f = @calculate_slope;
            [res(count).jid_upslp,res(count).upslp_per_triad] = jid_per_param(res(count).refilter.channels,res(count).selected_waves,res(count).dt_dt_r, f, 'sel_field',"mxupslp");
        end
        %% create the jid and perform NNMFfor the downward slopes
        if options.get_jid_dnslp
            % downward slopes JID
            f = @calculate_slope;
            [res(count).jid_dnslp,res(count).dnslp_per_triad] = jid_per_param(res(count).refilter.channels,res(count).selected_waves,res(count).dt_dt_r, f, 'sel_field',"mxdnslp");
        end
        %% save results
        count = count+1;
        if options.save_results
            save(sprintf('%s/%s_res_%d',options.save_path,options.file, pp),'res')
        end
    end
end
end