function [data,EEG] = sw_detection(EEG, participant, options)
%% Preprocess EEG data and generate ERP or ERSP
%
% **Usage:** [data] = process_EEG(EEG, participant)
%        - process_EEG(..., 'aligned', 1)
%        - process_EEG(..., 'epoch_window_ms', [-2000 2000])
%
%  Input(s):
%   - EEG = EEG struct
%   - participant = string with participant ID/name
%   - options = struct with  
%           - options.epoch_window_ms **optional** cell (1,2) = epoch window in ms (e.g. [-1000 500])
%           - options.epoch_window_baseline **optional** cell (1,2) = baseline window in MS (e.g. [-1000 -800])
%           - options.erp_data = load erp data (1) or ersp data (0)
%           - options.cycles **optional** double = [1 0.5] 0 for FFT or array for wavelet transform (See newtimef cycles)
%           - options.bandpass_upper **optional** = upper range bandpass filter
%           - options.bandpass_lower **optional** = lower range bandpass filter
%           - options.aligned  **optional** logical = Load aligned (1) or unaligned (0) data
%           - option.delay  **optional** = Known delay for participant (used for alignment correction, assumed aligned is 0)
% 
%  Output(s):
%   - data = cell with generated erp or ersp 
%       erp: data{1} = Participant;
%            data{2} = ERP based on trimmedmean leaving out top and bottom 20%
%            data{3} = ERP mean
%            data{4} = Epoched data channel x time x trial;
%            data{5} = Delay based on previous alignment model;
%       ersp: data{channel,1} = Participant;
%             data{channel,2} = ERSP powers;
%             data{channel,3} = Number of trials;
%             data{channel,4} = Real times;
%             data{channel,5} = Frequencies;
%             data{channel,6} = Channel number;
%             data{channel,7} = Time-frequency power for each trial;
%
% Author: R.M.D. Kock

if isfield(EEG, 'Aligned.BS_to_tap')
    % epoch around aligned tap
    num_taps = size(find(EEG.Aligned.BS_to_tap.Phone == 1),2);
    [EEG] = add_events(EEG,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
end
% [EEG_taps,indexes] = prepare_EEG_w_taps_only(EEG_taps);
[EEG_taps] = preprocess_EEG(EEG);
[twa_results]= twalldetectnew_TA_v4(EEG_taps.data,EEG.srate,0);
refilter = filter_results(twa_results);
EEG_taps.data = [];
%%
data{1} = participant;
% ERP based on trimmedmean leaving out top and bottom 20%
data{2} = EEG_taps;
data{3} = twa_results;
data{4} = refilter;
% data{5} = indexes;

end