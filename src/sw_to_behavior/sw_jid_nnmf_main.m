function sw_jid_nnmf_main(res,options)
%% perform NNMF on for each participant 
%
% **Usage:**
%   -  sw_jid_nnmf_main(res)
%   -  sw_jid_nnmf_main(...,'mins',2)
%
%  Input(s):
%   - res = struct array with the sw to behavior features containing fields: res.refilter
%
%  Optional Input(s):
%   - save_results (Default : 1) = 1 save results, 0 otherwise
%   - save_path (Default : current directory) = string path to save results
%   - file (Default: empty) = Unique checkpoint file name to save results
%   - parameter (Default : 1) = number of minutes to select after a triad for post_rate and pre_rate
%   - repetitions_cv (Default : 50) = number of repitions for cross validation
%   - z_score (Default : 0) = 1 zscore normalize data before NNMF, 0 otherwise
%   - threshold(Default : 0) = 1 threshold empty bins before NNMF, 0 otherwise
%   - log_transform(Default : 0) = 1 log_transform data before NNMF, 0 otherwise
%
%  Output(s):
%
% Author: R.M.D. Kock, Leiden University, 2024
arguments
    res;
    options.save_results logical = 1;
    options.save_path char = '.';
    options.file = '';
    options.parameter = 'sw_jid';
    options.repetitions_cv = 50;
    options.z_score = 0;
    options.threshold = 0;
    options.log_transform = 0;
end

for pp=1:length(res)
    jid_all_chans = cell(64,1); 
    % prepare sw jid per channel
    for chan=1:64
        if strcmp(options.parameter, 'sw_jid')
            jid_all_chans{chan} = taps2JID([res(pp).refilter.channels(chan).negzx{:}]);
        elseif strcmp(options.parameter, 'sw_rate')
            taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).rate);
            triad_lengths_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).triad_lengths);
            rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
            %rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
            jid_all_chans{chan} = reshape([rate_jid{:}],50,50);
        end
    end

    % prepare data for nnmf
    [reshaped_jid_all_chans,kept_bins] = prepare_sw_data_for_nnmf(jid_all_chans,'zscore', options.z_score, 'threshold',options.threshold, 'log_transform',options.log_transform);
    % perform NNMF
    [reconstruct_all_chans,stable_basis_all_chans] = perform_sw_param_nnmf(reshaped_jid_all_chans,kept_bins, 'repetitions_cv',options.repetitions_cv);
    % save results
    if options.save_results
        save(sprintf('%s/jid_all_chans_%d',options.save_path, pp),'jid_all_chans')
        save(sprintf('%s/reshaped_jid_amp_%d',options.save_path, pp),'reshaped_jid_all_chans')
        save(sprintf('%s/reconstruct_%d',options.save_path, pp),'reconstruct_all_chans')
        save(sprintf('%s/stable_basis_%d',options.save_path, pp),'stable_basis_all_chans')
    end
   
end
