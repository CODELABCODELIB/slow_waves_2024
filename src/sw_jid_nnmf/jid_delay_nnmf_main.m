function jid_delay_nnmf_main(res,f,options)
arguments
    res;
    f function_handle;
    options.save_results logical = 1;
    options.save_path char = '.';
    options.parameter = '';
    options.file = '';
    options.repetitions_cv = 50;
    options.z_score = 0;
    options.threshold = 0;
    options.log_transform = 0;
    options.n_timelags = [0:0.5:10];
end
for pp=1:length(res)
    taps = res(pp).taps;
    refilter = res(pp).refilter;
    dt_dt_r =  res(pp).dt_dt_r;
    [jid_delays] = jid_param_before_during_after(taps,refilter,f,dt_dt_r,'n_timelags',options.n_timelags);
    if options.save_results
        save(sprintf('%s/%s_jid_delays_%s_%d',options.save_path,options.file, pp),'jid_delays')
    end
    reshaped_jid_all_chans = cell(64,1);
    reconstruct_all_chans = cell(64,1);
    stable_basis_all_chans = cell(64,1);
    for chan=1:64
        [reshaped_jid_all_chans{chan},kept_bins] = prepare_sw_data_for_nnmf(jid_delays(chan,:)','zscore', options.z_score, 'threshold',options.threshold, 'log_transform',options.log_transform);
        if ~isempty(reshaped_jid_all_chans{chan})
            [reconstruct_all_chans{chan},stable_basis_all_chans{chan}] = perform_sw_param_nnmf(reshaped_jid_all_chans{chan},kept_bins, 'repetitions_cv',options.repetitions_cv);
        end
    end
    if options.save_results
        save(sprintf('%s/%s_reshaped_jid_amp_%s_%d',options.save_path,options.file, pp),'reshaped_jid_all_chans')
        save(sprintf('%s/%s_reconstruct_%s_%d',options.save_path,options.file, pp),'reconstruct_all_chans')
        save(sprintf('%s/%s_stable_basis_%s_%d',options.save_path,options.file, pp),'stable_basis_all_chans')
    end
end
