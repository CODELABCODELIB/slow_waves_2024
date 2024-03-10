function [topX_filtered_results] = filter_results_thresh(results)

% Filtering steps adopted from Andrillon et al. (2021)

filtered_results = results; % Copy the original results to preserve the structure

for ch = 1:length(filtered_results.channels) % Iterate through each channel
    wave_indices_to_remove = []; % Initialize an array to keep track of waves to remove
    
    for wi = 1:length(filtered_results.channels(ch).maxpospkamp) % Iterate through each wave
        % Filter 1: Check for positive peak > 75 μV
        if filtered_results.channels(ch).maxpospkamp{wi} > 75
            wave_indices_to_remove = [wave_indices_to_remove, wi]; % Mark for removal
            continue; % Move to the next wave
        end
        
        % Filter 2: Check for large-amplitude events (> 150 μV) in extended time window
        maxamp = max(filtered_results.channels(ch).maxampwn{wi}, abs(filtered_results.channels(ch).minampwn{wi}));
        if maxamp > 150
            wave_indices_to_remove = [wave_indices_to_remove, wi]; % Mark for removal
        end
    end
    
    % Remove marked waves from filtered_results
    fields = fieldnames(filtered_results.channels(ch)); % Get all wave parameter fields
    for field_idx = 2:length(fields) % Start at field index 2 because of field "datalength" (length = 1)
        field = fields{field_idx};
        filtered_results.channels(ch).(field)(wave_indices_to_remove) = []; % Remove entries for each field
    end
end

thresh_nums = [80, 85, 90, 95];
topX_filtered_results = struct(); % Initialize final struct
topX_filtered_results.threshs = cell(length(thresh_nums), 1); % Initialize threshs cell array

for thr_ind = 1:length(thresh_nums) % Iterate through different p2p-amp thresholds
    topX_filtered_results.threshs{thr_ind} = filtered_results; % Initialize a copy of filtered_results for modification
    for ch = 1:length(filtered_results.channels) % Iterate through each channel
        current_channel_p2p_amps = abs([filtered_results.channels(ch).maxnegpkamp{:}]) + [filtered_results.channels(ch).maxpospkamp{:}]; % Current channel's p2p amplitudes
        threshold = prctile(current_channel_p2p_amps, thresh_nums(thr_ind)); % Calculate the X'th percentile as the threshold
        
        waves_to_keep = find(current_channel_p2p_amps >= threshold); % Find indices of waves that are in the top (100-X)%
        
        % Now filter each parameter in the channel to keep only the top (100-X)% waves
        fields = fieldnames(filtered_results.channels(ch)); % Get all wave parameter fields
        for field_idx = 2:length(fields) % Start at field index 2 because of field "datalength" (length = 1)
            field = fields{field_idx};
            topX_filtered_results.threshs{thr_ind}.channels(ch).(field) = topX_filtered_results.threshs{thr_ind}.channels(ch).(field)(waves_to_keep);
        end
    end
end

end