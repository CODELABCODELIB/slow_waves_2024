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
%   - n_bins (Default : 50) = size of jid bins 
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
    options.n_bins = 50;
end

for pp=1:length(res)
    jid_all_chans = cell(64,1); 
    % prepare sw jid per channel
    for chan=1:62
        if strcmp(options.parameter, 'sw_jid')
            sw_jid = taps2JID([res(pp).behavior_sws{chan,:}]);
            jid_all_chans{chan} = reshape(sw_jid,2500,1);
        elseif strcmp(options.parameter, 'sw_jid_movie')
            sw_jid = taps2JID([res(pp).movie_sws{chan,:}]);
            jid_all_chans{chan} = reshape(sw_jid,2500,1);
        elseif strcmp(options.parameter, 'sw_amplitude')
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).amplitude);
            jid_sw_amplitude = cellfun(@(x) median(x),taps_on_sw{chan}, 'UniformOutput',0);
            jid_all_chans{chan} =  reshape([jid_sw_amplitude{:}],2500,1);
        elseif strcmp(options.parameter, 'sw_rate')
            taps_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).rate);
            triad_lengths_on_sw = assign_input_to_bin([res(pp).behavior_sws{chan,:}],res(pp).triad_lengths);
            rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
            %rate_jid(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
            tmp = rate_jid; 
            % tmp(reshape([rate_jid{:}] == 0, 50,50)) = {NaN};
            % binarize the rates
            % rate_jid(reshape([rate_jid{:}] > 0, 50,50)) = {1};
            % rate without the behaviors
            jid_all_chans{chan} = reshape([tmp{:}],2500,1);
        end
    end

    % prepare data for nnmf
    [reshaped_jid_all_chans,kept_bins] = prepare_sw_data_for_nnmf(jid_all_chans,'zscore', options.z_score, 'threshold',options.threshold, 'log_transform',options.log_transform, 'n_bins', options.n_bins);
    % perform NNMF
    [reconstruct_all_chans,stable_basis_all_chans] = perform_sw_param_nnmf(reshaped_jid_all_chans,kept_bins, 'repetitions_cv',options.repetitions_cv, 'n_bins',options.n_bins);
    % save results
    if options.save_results
        save(sprintf('%s/jid_all_chans_%d',options.save_path, pp),'jid_all_chans')
        save(sprintf('%s/reshaped_jid_amp_%d',options.save_path, pp),'reshaped_jid_all_chans')
        save(sprintf('%s/kept_bins_%d',options.save_path, pp),'kept_bins')
        save(sprintf('%s/reconstruct_%d',options.save_path, pp),'reconstruct_all_chans')
        save(sprintf('%s/stable_basis_%d',options.save_path, pp),'stable_basis_all_chans')
    end
   
end
