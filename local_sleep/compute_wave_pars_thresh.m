function [wave_pars] = compute_wave_pars_thresh(topX_filtered_results, fs_original)

wave_pars = struct();
wave_pars.threshs = struct(); % Initialize threshs struct

for thr_ind = 1:length(topX_filtered_results.threshs) % Iterate through different thresholds
    for ch = 1:length(topX_filtered_results.threshs{thr_ind}.channels) % Iterate through each channel
        channel_data = topX_filtered_results.threshs{thr_ind}.channels(ch);

        % Computing slow-wave density for the channel
        wvspermin(ch) = length([channel_data.maxnegpkamp{:}]) / (channel_data.datalength / 128 / 60);

        % Computing mean peak-to-peak amplitude for the channel
        p2pamp(ch) = mean(abs([channel_data.maxnegpkamp{:}]) + [channel_data.maxpospkamp{:}]);

        % Computing mean downward slope for the channel
        dslope(ch) = mean(abs([channel_data.maxnegpkamp{:}]) ./ (([channel_data.maxnegpk{:}] - [channel_data.negzx{:}]) / fs_original));

        % Computing mean upward slope for the channel
        uslope(ch) = mean((abs([channel_data.maxnegpkamp{:}]) + [channel_data.maxpospkamp{:}]) ./ (([channel_data.maxpospk{:}] - [channel_data.maxnegpk{:}]) / fs_original));
    end

    % Store the computed parameters for the threshold
    wave_pars.threshs(thr_ind).wvspermin = wvspermin;
    wave_pars.threshs(thr_ind).p2pamp = p2pamp;
    wave_pars.threshs(thr_ind).dslope = dslope;
    wave_pars.threshs(thr_ind).uslope = uslope;
end

end