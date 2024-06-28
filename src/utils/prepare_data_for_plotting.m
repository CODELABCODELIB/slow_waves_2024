function [mean_vals, sig_t,sig_m] = prepare_data_for_plotting(one_sample, mask, paired, tf,options)
arguments
    one_sample
    mask
    paired logical
    tf logical
    options.c_range = [13:30];
    options.ams = [];
    options.nams = [];
end
mean_vals = []; sig_t = [];
electrodes = 62;
freq_size = size(mask,2);
time_size = size(mask,3);
%%
if size(one_sample,1) ~=electrodes
    one_sample = one_sample(1:62,:,:);
    mask = mask(1:62,:,:);
end
%% get means for figure 2 or 3 i
if paired
    if ~isempty(options.ams) && ~isempty(options.nams) && ~tf
        % difference AM - NAM
        mean_vals_am = trimmean(options.ams, 20, 3);
        mean_vals_nam = trimmean(options.nams, 20, 3);
        mean_vals = mean_vals_am - mean_vals_nam;
        % apply mask
        %         x = logical(mask);
        %         sig_m = x.*mean_vals;
    end
else
    if tf
        one_sample_reshaped = limo_tf_4d_reshape(one_sample, [electrodes, freq_size,time_size, 5]);
        mean_vals = squeeze(one_sample_reshaped(:, :, :, 1));
        x = logical(mask);
        sig_m = x.*mean_vals;
        mean_vals = squeeze(trimmean(mean_vals(:,options.c_range,:),20,2));
        sig_m = squeeze(trimmean(sig_m(:,options.c_range,:),20,2));
    else
        mean_vals = squeeze(one_sample(:, :, 1));
        x = logical(mask);
        sig_m = x.*mean_vals;
    end
end
%% get t values for figure 2 or 3 ii
if tf
    one_sample_reshaped = limo_tf_4d_reshape(one_sample, [electrodes, freq_size,time_size, 5]);
    t_vals = squeeze(one_sample_reshaped(:, :, :, 4));
    x = logical(mask);
    sig_t = x.*t_vals;
    % get the largest t value either positive or negative
    [minA, maxA] = bounds(sig_t(:,options.c_range,:),2);
    [b, I] = max([abs(minA), abs(maxA)], [], 2);
    final_index = [(I == 1) (I == 2)];
    c = [minA, maxA];
    sig_t = reshape(c(final_index), [electrodes 200]);
else
    t_vals = squeeze(one_sample(:, :, 4));
    x = logical(mask);
    sig_t = x.*t_vals;
end
end
