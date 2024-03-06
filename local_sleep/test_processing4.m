function [processed_EEG] = test_processing4(EEG, ref_electrodes)

% Check if ref_electrodes argument is passed
if nargin < 2
    % If ref_electrodes are not passed, default to [52 58]
    ref_electrodes = [52 58];
end

% Initialize struct array for processed EEG data
processed_EEG = struct();

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

% Select movie/phone parts of the EEG data
Movie = pop_select(EEG, 'point', [1 4231882]);
Phone = pop_select(EEG, 'point', [4231882 7101108]);

processed_EEG.Complete = EEG;
processed_EEG.Movie = Movie;
processed_EEG.Phone = Phone;

end