function [reshaped_jid,kept_bins] = prepare_sw_data_for_nnmf(jid_param,options)
arguments
    jid_param
    options.threshold = 0.75;
    options.zscore logical = 0;
    options.log_transform logical = 0;
    options.n_bins = 50;
end
reshaped_jid = cellfun(@(JID) reshape(JID,2500,1) ,jid_param,'UniformOutput' ,false);
reshaped_jid = [reshaped_jid{:}];
if options.zscore
    reshaped_jid = nanzscore(reshaped_jid);
end
% remove the completely empty bins before NNMF
removed_bins = isnan(reshaped_jid);
kept_bins_idx = find(~all(removed_bins'));
reshaped_jid = reshaped_jid(kept_bins_idx,:);

if options.threshold
    % remove the bins that are more than 75% empty compared to the other bins
    num_empty_cells = sum(isnan(reshaped_jid),2);
    kept_bins_2 = num_empty_cells < quantile(num_empty_cells, options.threshold);
    reshaped_jid = reshaped_jid(kept_bins_2,:);

    % index of the kept bins to assign later
    kept_bins = logical(zeros(options.n_bins*options.n_bins,1));
    kept_bins(kept_bins_idx(kept_bins_2)) = 1;
else
    kept_bins = logical(zeros(options.n_bins*options.n_bins,1));
    kept_bins(kept_bins_idx) = 1;
end

if ~isempty(reshaped_jid)
    if ~options.log_transform
        reshaped_jid = reshaped_jid + abs(min(reshaped_jid, [],'all'));
        reshaped_jid(isnan(reshaped_jid)) = 0.000000000000000001;
    else
        reshaped_jid(reshaped_jid == 0) = NaN;
        reshaped_jid(isnan(reshaped_jid)) = 0.000000000000000001;
        reshaped_jid = log10(reshaped_jid) + abs(min(log10(reshaped_jid), [],'all'));
        % if  abs(min(log10(reshaped_jid)))
        %     reshaped_jid = log10(reshaped_jid) + abs(min(log10(reshaped_jid), [],'all'));
        % else
            % reshaped_jid = log10(reshaped_jid) + abs(min(log10(reshaped_jid))) + 0.000000000000000001;
        % end
    end
end
end