function [flt_data] = getcleanedbsdata(bsvals,fs,range);
% Usage. [DataOut numrej idjrej]= getcleanedbsdata(DataIn,fs, range)
% Performs, outlier detection, removal and bandpass filtering 
%
% Input(s):
%   - DataIn, are the bendsensor values
%   - fs, is the sample rate as in 1000 samples per second
%   - range, is the freq. range in Hz
% DataOut is filtered data
% Uses broad Hampel filter followed by narrow hampel filter 
%
% Arko Ghosh, Leiden University% 

if isempty(range)
    range = [0.5 5]; 
end

%% Remove slow drifts in data


% Format to EEG data to use filters 
EEG.data = bsvals'; % add 100 so that iqr is not zero 
EEG.pnts = length(EEG.data);
EEG.srate = fs; 
EEG.pnts = length(EEG.data);
EEG.trials = 1; 
EEG.event.type = [];
EEG.nbchan = 1;



%% Re-scale the data 
EEG.data = (EEG.data -nanmedian(EEG.data ))./iqr(EEG.data);
EEG.data(isnan(EEG.data))= 0; 
%% Remove unreasoble values 
EEG.data(abs(EEG.data)>6) = 0; 

%% Remove slow drivts 
EEG = pop_eegfiltnew(EEG,range(1), []);


%% Finally, perform a bandpass filter with the view that the fastest movements are of interest 
try
EEG = pop_eegfiltnew(EEG, [], range(2));
end
flt_data = EEG.data; 
end