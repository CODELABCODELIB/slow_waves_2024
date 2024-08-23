function OUTEEG = gettechnicallycleanEEG(INEEG, bandpass_upper_range,bandpass_lower_range)
% OUTEEG = gettechnincallycleanEEG(INEEG,bandpass_upper_range)
% 
% Input(s):
%   - INEEG: EEG struct to process
%   - bandpass_upper_range: Upper range for bandpass filtering of EEG data 
% 
% Assume 1.ICA performed, 2. Bad channels have been marked, 3. channel locations already placed 4. Electrode locations present 
% Performs the following steps
%   1. Remove blinks according to ICA
%   2. Interpolate missing channels 
%   3. Re-reference data to average channel 
%
% pop_jointprob( EEG, 1, [1:62],5, 5, [0], 1, 0);
% Remove non_EEG data
%
% Arko Ghosh, Leiden University
% Added at line 43 -- [INEEG] = pop_eegfiltnew(INEEG, 0.5, []); 
%
%%
idxr = find(strcmp({INEEG.chanlocs.labels}, 'x_dir') == true);% are blink channels present 
if idxr>0
   INEEG.data(idxr:idxr+2,:) = []; 
   INEEG.nbchan = idxr-1;
   
end

% Remove blinks based on ICA 

idx = find(strcmp({INEEG.chanlocs.labels}, 'E64')|strcmp({INEEG.chanlocs.labels}, 'E63') == true);% are blink channels present 

rej = []; 
for i = 1:length(idx)
INEEG.icaquant{i} = icablinkmetrics(INEEG, 'ArtifactChannel', INEEG.data(idx(i),:), 'Alpha', 0.001, 'VisualizeData', 'False');
rej = [rej INEEG.icaquant{1,i}.identifiedcomponents]; 
end

% run TESA
%EEG = pop_tesa_compselect( INEEG, 'compCheck', 'off', 'tmsMuscle', 'off', 'muscle', 'off', 'elecNoise','off','elecNoiseThresh',5 ,'blinkThresh',3,'blinkElecs',{'E63', 'E64'},'blinkFeedback','on', 'moveElecs', {'E36', 'E48'},'plotTimeX', [1 INEEG.pnts-1]);
%rejtesa = [EEG.icaCompClass.TESA1.rejectBlink EEG.icaCompClass.TESA1.rejectEyeMove EEG.icaCompClass.TESA1.rejectElectrodeNoise]; 

Rej_Comp = unique([rej]);
INEEG = pop_subcomp(INEEG,Rej_Comp,0);

oIdx = cellfun(@(s) strcmp('_dir', s(2:end)), {INEEG.Orignalchanlocs.labels}, 'UniformOutput', true);
INEEG.Orignalchanlocs(oIdx) = []; clear oIdx; 
oIdx = cellfun(@(s) strcmp('_dir', s(2:end)), {INEEG.chanlocs.labels}, 'UniformOutput', true);
INEEG.chanlocs(oIdx) = []; 

% interpolate missing channels 
INEEG = pop_interp(INEEG,INEEG.Orignalchanlocs,'spherical');

% Final Filter 
if ~isempty(bandpass_upper_range)
[INEEG] = pop_eegfiltnew(INEEG, [], bandpass_upper_range);
end
if ~isempty(bandpass_lower_range)
% Remove if slow
[INEEG] = pop_eegfiltnew(INEEG, bandpass_lower_range, []);
end 

% Re-reference to average channel 

OUTEEG = pop_reref (INEEG, [1:62], 'keepref', 'on'); 

OUTEEG = eeg_checkset(INEEG); % use this re-ref to avg reference.
