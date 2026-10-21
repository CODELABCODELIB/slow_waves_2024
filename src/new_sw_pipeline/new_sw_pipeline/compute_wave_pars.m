function [wave_pars] = compute_wave_pars(top10_filtered_results, fs_original)

wave_pars = struct();

% Computing slow-wave density for each channel
wvspermin = arrayfun(@(x) length([x.maxnegpkamp{:}]) / (x.datalength / 128 / 60), top10_filtered_results.channels);

% Computing mean peak-to-peak amplitude for each channel
p2pamp = arrayfun(@(x) mean(abs([x.maxnegpkamp{:}]) + [x.maxpospkamp{:}]), top10_filtered_results.channels);

if isfield(top10_filtered_results.channels, 'maxnegpk_input')
    fs = top10_filtered_results.input_srate;
    dslope = arrayfun(@(x) mean(abs([x.maxnegpkamp{:}]) ./ ...
        (([x.maxnegpk_input{:}] - [x.negzx_input{:}]) / fs)), top10_filtered_results.channels);
    uslope = arrayfun(@(x) mean((abs([x.maxnegpkamp{:}]) + [x.maxpospkamp{:}]) ./ ...
        (([x.maxpospk_input{:}] - [x.maxnegpk_input{:}]) / fs)), top10_filtered_results.channels);
else
% Computing mean downward slope for each channel
dslope = arrayfun(@(x) mean(abs([x.maxnegpkamp{:}]) ./ (([x.maxnegpk{:}] - [x.negzx{:}]) / fs_original)), top10_filtered_results.channels);

% Computing mean upward slope for each channel
uslope = arrayfun(@(x) mean((abs([x.maxnegpkamp{:}]) + [x.maxpospkamp{:}]) ./ (([x.maxpospk{:}] - [x.maxnegpk{:}]) / fs_original)), top10_filtered_results.channels);

end

wave_pars.wvspermin = wvspermin;
wave_pars.p2pamp = p2pamp;
wave_pars.dslope = dslope;
wave_pars.uslope = uslope;

end