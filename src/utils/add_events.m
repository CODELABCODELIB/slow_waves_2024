function [EEG] = add_events(EEG,data,num,type)
%% Adds identified events to EEG.event and EEG.urevent
% In this case the events are predicted peak locations or tap locations
%
% **Usage:** [EEG] = add_events(EEG,data,num,type)
%
%
% Input(s):
%   - EEG = EEG struct
%   - data = the event indices
%   - num = number of events
%   - type = char array (' ') denoting event type
%     (phone taps are denoted as pt and predictions as pred_d for deltas and pred_i for integrals)
%
% Output(s):
%   - EEG = EEG struct with added EEG events
%
% Author: R.M.D. Kock, Leiden University

%%
% latency is the time event took place
latency = num2cell(data);
% duration of event (always 1 ms)
duration = num2cell(ones(num,1))';
% channel (NA set as 0)
channel = num2cell(zeros(num,1))';
% bvtime (NA)
bvtime = [];
% bvtime (NA)
bvmknum = [];
% type of event
type = repmat({type},[1,num]);
code = repmat({'Stimulus'},[1,num]);
% urevent timing
last_urevent = size(EEG.event,2);
urevents = num2cell([last_urevent+1:last_urevent+num]);

s_1 = struct('latency',latency,'duration',duration,'channel',channel,'bvtime',bvtime,'bvmknum',bvmknum,'type',type,'code',code, 'urevent', urevents);
s_2 = struct('latency',latency,'duration',duration,'channel',channel,'bvtime',bvtime,'bvmknum',bvmknum,'type',type,'code',code);
combi_completa_1 = mergeStructs(EEG.event,s_1);
combi_completa_2 = mergeStructs(EEG.urevent,s_2);
EEG.event = combi_completa_1;
EEG.urevent = combi_completa_2;
end
