function sw_jid_nnmf_main(res,options)
arguments
    res;
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
    jid_all_chans = cell(64,1);
    reshaped_jid_all_chans = cell(64,1);
    reconstruct_all_chans = cell(64,1);
    stable_basis_all_chans = cell(64,1);
    
    for chan=1:64
        jid_all_chans{chan} = taps2JID([res(pp).refilter.channels(chan).negzx{:}]);
    end
    [reshaped_jid_all_chans{chan},kept_bins] = prepare_sw_data_for_nnmf(jid_all_chans(chan)','zscore', options.z_score, 'threshold',options.threshold, 'log_transform',options.log_transform);
    if options.save_results
        save(sprintf('%s/jid_all_chans_%d',options.save_path, pp),'jid_all_chans')
        save(sprintf('%s/reshaped_jid_amp_%d',options.save_path, pp),'reshaped_jid_all_chans')
        save(sprintf('%s/reconstruct_%d',options.save_path, pp),'reconstruct_all_chans')
        save(sprintf('%s/stable_basis_%d',options.save_path, pp),'stable_basis_all_chans')
    end
end
