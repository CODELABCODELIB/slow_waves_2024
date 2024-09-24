function [data,EEG] = sw_detection(EEG, participant, options)
%% Preprocess EEG data and generate ERP or ERSP
%
% **Usage:** [data] = process_EEG(EEG, participant)
%        - sw_detection(EEG, participant)
%        - sw_detection(..., 'pt', 1)
%
%  Input(s):
%   - EEG = EEG struct
%   - participant = string with participant ID/name
%
%  Optional Input(s):
%   - pt (Default : 1) = 1 select and run analysis on only behavioral data
%           0 run analysis on full dataset including resting state and movie
%
%  Output(s):
%   - data = cell with generated sw data
%       - data{1} = Participant folder name
%       - data{2} = EEG struct without EEG.data
%           EEG.phone_indexes = the timeperiods including phone touches
%           EEG.taps = timestamps of the taps 
%           EEG.movie_indexes = the timeperiods including movie 
%       - data{3} = twa_results set with SWs (outcome of twalldetectnew_TA_v4)
%       - data{4} = refilter sw after thresholding (outcome of filter_results);
%
%  Requires:
%   -add_events.m 
%   -preprocess_EEG.m
%   -twalldetectnew_TA_v4.m
%   -filter_results.m
%
% Author: R.M.D. Kock, Leiden University

%% select the smartphone events 
% if isfield(EEG, 'Aligned.BS_to_tap') && ~options.pt
%     % epoch around aligned tap
%     num_taps = size(find(EEG.Aligned.BS_to_tap.Phone == 1),2);
%     [EEG] = add_events(EEG,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
%     EEG.latencies = [EEG.event.latency]; 
%     EEG.taps = latencies(strcmp({EEG.event.type}, 'pt'));
%     [EEG.phone_indexes] = find_gaps_in_taps(taps);
% end
% % perform SW detection on smartphone events only
% if isfield(EEG, 'Aligned.BS_to_tap') && options.pt
%     [EEG,indexes] = prepare_EEG_w_taps_only(EEG_taps);
%     EEG.indexes = indexes;
% end
% 
% %% SW detection
% [EEG] = preprocess_EEG(EEG);
% [twa_results]= twalldetectnew_TA_v4(EEG.data,1000,0);
% refilter = filter_results(twa_results);

%% data to save
% if options.remove_EEG
%     EEG.data = [];
% end
data{1} = participant;
% EEG.data removed due to save time
data{2} = EEG;
% data{3} = twa_results;
% data{4} = refilter;

end