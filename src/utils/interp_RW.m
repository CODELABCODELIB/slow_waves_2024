function [load_data] = interp_RW(load_data, index, split, options)
%% Interpolate erp data for RW participants with lower sampling frequencies
% RW participants were sampled at 500 Hz wheras other participants at 1000
% Hz. This function interpolates the data of RW participants to 1000 Hz.
% Can be used for any participants as long as sampling rate is < 1000 Hz and needs to be doubled 
%
% **Usage:** [load_data] = interp_RW(load_data, index, split)
%       - interp_RW(... 'time_range', 4000)
%       - interp_RW(... 'channels', 62)
%
%  Input(s):
%   - load_data = cell containing eeg data (see process_EEG)
%   - index = ERP data index 
%       - 2: ERP based on trimmedmean leaving out top and bottom 20% 
%       - 3: ERP based on mean
%       - 4: Epoched data channel x time x trial;
%   - split = Whether the trials the interpolation should (1) or shouldn't (0) occur for each trial
%   - options.time_range **Optional** = Total size of epoch window in ms
%   - options.channels **Optional** = maximum number of channels
%
%  Output(s):
%   - load_data = cell containing eeg data (see process_EEG) with
%   interpolated erp for RW participants
%
% Author: R.M.D. Kock
% 

arguments 
    load_data cell;
    index double;
    split logical;
    options.time_range double = 10000;
    options.channels double = 64;
end
%%

mask = cellfun(@(x) size(x,2)<options.time_range,load_data(:,index), 'UniformOutput', false);
RW = load_data(cell2mat(mask),index);
for i=1:length(RW)
    if split
        trials = size(RW{i},3);
        all = zeros(options.channels,options.time_range,trials, 'single');
        for chan=1:options.channels
            for trial=1:trials
                all(chan,:,trial) = interp(RW{i}(chan,:,trial), 2);
            end
        end
    else
        all = zeros(options.channels,options.time_range, 'single');
        for chan=1:options.channels
            all(chan,:) = interp(RW{i}(chan,:), 2);
        end
    end
    RW{i} = all;
end
load_data(cell2mat(mask),index) = RW;
end