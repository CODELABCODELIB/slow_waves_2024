function [wave_pars] = compute_wave_pars2(top10_filtered_results, fs_original)

wave_pars = struct();
wave_pars.segments = struct(); % Initialize the segments structure

% Iterate through each segment
for seg = 1:length(top10_filtered_results.segments)
    
    % Iterate through each channel within the segment
    for ch = 1:length(top10_filtered_results.segments(seg).channels)
        channel_data = top10_filtered_results.segments(seg).channels(ch);

        % Computing slow-wave density for the channel
        wvspermin(ch) = length([channel_data.maxnegpkamp{:}]) / (channel_data.datalength / 128 / 60);

        % Computing mean peak-to-peak amplitude for the channel
        p2pamp(ch) = mean(abs([channel_data.maxnegpkamp{:}]) + [channel_data.maxpospkamp{:}]);

        % Computing mean downward slope for the channel
        dslope(ch) = mean(abs([channel_data.maxnegpkamp{:}]) ./ (([channel_data.maxnegpk{:}] - [channel_data.negzx{:}]) / fs_original));

        % Computing mean upward slope for the channel
        uslope(ch) = mean((abs([channel_data.maxnegpkamp{:}]) + [channel_data.maxpospkamp{:}]) ./ (([channel_data.maxpospk{:}] - [channel_data.maxnegpk{:}]) / fs_original));
    end

    % Store the computed parameters for the segment
    wave_pars.segments(seg).wvspermin = wvspermin;
    wave_pars.segments(seg).p2pamp = p2pamp;
    wave_pars.segments(seg).dslope = dslope;
    wave_pars.segments(seg).uslope = uslope;
end

end