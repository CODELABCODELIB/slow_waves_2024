function [processed_EEG] = test_processing4(EEG, varargin)

% Arguments: 'EEG', 'data_part' (optional; 'movie'/'phone'), 'ref_electrodes' (optional)

% Initialize default for 'ref_electrodes'
ref_electrodes = [52 58];

% Parse varargin for 'data_part' and 'ref_electrodes'
if ~isempty(varargin)
    for i = 1:length(varargin)
        if strcmpi(varargin{i}, 'data_part')
            data_part = varargin{i+1};
        elseif strcmpi(varargin{i}, 'ref_electrodes')
            ref_electrodes = varargin{i+1};
        end
    end
end

% Process EEG data based on 'data_part'
if exist('data_part', 'var')
    switch data_part
        case 'movie'
            EEG = pop_select(EEG, 'point', [1 4231882]); % Select movie part of EEG data
        case 'phone'
            EEG = pop_select(EEG, 'point', [4231882 7101108]); % % Select phone part of EEG data
    end
end

% Apply high-pass filter >0.1 Hz using a two-pass fifth-order Butterworth filter
[bf, af] = butter(5, 0.1/(EEG.srate/2), 'high');
EEG.data = filtfilt(bf, af, double(EEG.data));

% Apply notch filter (stopband: [45, 55] Hz, fourth-order Butterworth filter) to remove line noise
notchFreq = [45 55]; % 45 to 55 Hz for 50 Hz line noise
[bf, af] = butter(4, notchFreq/(EEG.srate/2), 'stop');
EEG.data = filtfilt(bf, af, double(EEG.data));

% Re-reference the EEG signal
EEG = pop_reref(EEG, ref_electrodes, 'keepref', 'on');

% Band-pass filter the signal in the delta band (1-4 Hz)
EEG = pop_eegfiltnew(EEG, 1, 4);

processed_EEG = EEG;

end