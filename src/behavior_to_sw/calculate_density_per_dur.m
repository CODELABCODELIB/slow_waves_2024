function [densities] = calculate_density_per_dur(twa,max_time, options)
%% Calculate the density (number of slow waves) per min/ per electrode
%
% **Usage:**
%   - [densities] = density_per_min(twa,max_time)
%                 - density_per_min(...,'dur', 1000)
%                 - density_per_min(...,'n_electrodes', 62)
%
% Input(s):
%    twa = slow waves struct results (twa_results.channels)
%    max_time = duration of the EEG recording (length(EEG.times))
%
% Optional input parameter(s):
%    dur (default: 60000) = Time duration over which to calculate the density (in ms)
%    n_electrodes (default: 64) = Number of electrodes (in twa)
% Output(s):
%    densities struct = 
%       all (field) = The densities for all the minutes of recording
%       med (field) = Median density across all the minutes
%
% Ruchella Kock, Leiden University, 17/01/2024
%
arguments
    twa
    max_time
    options.dur = 60000;
    options.n_electrodes = length(twa);
end
densities = struct();
for chan=1:options.n_electrodes
    waves = [twa(chan).negzx{:}];
    n_mins = floor(max_time/options.dur);
    start_time = 1;
    density_ch = zeros(n_mins,1);
    for minute=1:n_mins-1
        end_time = start_time + options.dur;
        density_ch(minute) = sum(waves>start_time & waves<end_time);
        start_time = end_time;
    end
    density_ch(n_mins) = sum(waves>start_time & waves<max_time);
    densities(chan).all = density_ch;
    densities(chan).med = median(density_ch);
end