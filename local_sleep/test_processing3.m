function [processed_EEG] = test_processing3(EEG)

% Apply high-pass filter >0.1 Hz using a two-pass fifth-order Butterworth filter
EEG = pop_eegfiltnew(EEG, 0.1, [], [], 0, [], 0); % High-pass filter

% Apply notch filter (stopband: [45, 55] Hz, fourth-order Butterworth filter) to remove line noise
EEG = pop_eegfiltnew(EEG, 45, 55, [], 1); % Bandstop filter for notch effect

% % Extract/select epochs of [-1s, +2s] relative to event onset for the event code "S 34" with baseline correction
% EEG = pop_epoch(EEG, {'S 34'}, [-1 2], 'newname', 'Epochs extracted', 'epochinfo', 'yes', 'baseline', [-1000 2000]);

% Re-reference the EEG signal to the average of the mastoid electrodes (electrodes 52 and 58)
mastoid_indices = [52 58]; % Indices of mastoid electrodes
EEG = pop_reref(EEG, mastoid_indices, 'keepref', 'on'); % Re-reference to average of mastoids

% % Downsample the data to 128 Hz
% EEG = pop_resample(EEG, 128);

% Band-pass filter the signal in the delta band (1-4 Hz)
EEG = pop_eegfiltnew(EEG, 1, 4); % Delta band-pass filter

% % Apply a Type-2 Chebyshev bandstop filter
% Fs = 128; % Sampling frequency after downsampling
% Rp = 3;   % Passband ripple
% Rs = 25;  % Stopband attenuation
% Wp = [1 10] / (Fs / 2); % Normalized passband frequencies
% Ws = [0.1 15] / (Fs / 2); % Normalized stopband frequencies
% [n, ~] = cheb2ord(Wp, Ws, Rp, Rs); % Determine the minimum order of the filter
% [b, a] = cheby2(n, Rs, Ws, 'stop'); % Design the filter
% EEG.data = filtfilt(b, a, double(EEG.data)); % Apply the filter

processed_EEG = EEG;

end