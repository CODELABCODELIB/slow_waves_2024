function [ancova_models,indx_all] = generate_ancova_spectral_data(EEG_integrals_am,EEG_integrals_nam, participant, indx_all, ancova_models, options)
%% Creates a placeholder cell with the datasets of all participants for plotting of results
%
% **Usage:** [all_data,indx] = generate_spectral_data(EEG_integrals_am,EEG_integrals_nam, participant, indx, all_data, options)
%
% Input(s):
%   - EEG_integrals_am = EEG struct with epoched integral attributable movement data
%   - EEG_integrals_nam = EEG struct with epoched integral non attributable movement data
%   - participant = participant
%   - indx = index to place the participant data in cell
%   - all_data = cell placeholder cell with the data of the participants
%   - options =
%
% Output(s):
%   - all_data = cell placeholder cell with the data of one participant
%         all_data{indx_spec,1} = participant name
%         all_data{indx_spec,2} = power attributable movements (freq x time) (AM);
%         all_data{indx_spec,3} = power non attributable movements (freq x time) ;
%         all_data{indx_spec,4} = number of trials for attributable movements (AM);
%         all_data{indx_spec,5} = number of trials for non attributable movements (NAM);
%         all_data{indx_spec,6} = sequence of timesteps indication the original timepoints;
%         all_data{indx_spec,7} = sequence of frequencies used in analysis;
%         all_data{indx_spec,8} = electrode number;
%

all_data = {};
%% Thresholding data
% Options for thresholding
electrodes_to_reject = [1:62];
voltage_lower_threshold = -80; % In mV
voltage_upper_threshold = 80;
start_time = options.epoch_window_ms(1)/1000; % In sec
end_time = options.epoch_window_ms(2)/1000; % In sec
do_superpose = 0;
do_reject = 1;
% threshold the trials for AMs
try
    [EEG_integrals_am,indices_rej_integrals_am] = pop_eegthresh(EEG_integrals_am, 1, electrodes_to_reject, voltage_lower_threshold, voltage_upper_threshold, start_time, end_time, do_superpose, do_reject);
catch ME
    fprintf('EEGthresh error all trials removed', ME.message);
    return
end
% calculate the number of trials
trials_am = size(EEG_integrals_am.epoch,2);

% isempty(EEG_integrals_nam) occurs when the options.ersp_all_trials is 1 or rather
% options.seperate = 1. If that is not the case then the trials are all in
% EEG_integrals_am
if ~isempty(EEG_integrals_nam)
    try
        [EEG_integrals_nam,indices_rej_integrals_nam] = pop_eegthresh(EEG_integrals_nam, 1, electrodes_to_reject, voltage_lower_threshold, voltage_upper_threshold, start_time, end_time, do_superpose, do_reject);
    catch ME
        fprintf('EEGthresh error all trials removed', ME.message);
        return
    end
    % calculate the number of trials
    trials_nam = size(EEG_integrals_nam.epoch,2);
else
    % else set trials >50 to still do the analysis
    trials_nam = 51;
end
%% wavelet transform to generate ersps
% array of channels to create
channels = [1:64];
indx = 1;
% check if there are atleast 50 trails for both ams and nams
if (trials_am > 50) && (trials_nam > 50)
    % repeat for every channel
    for chan_idx=1:length(channels)
        channel = channels(chan_idx);
        [P_am,timesout,freqs, ~, PA] = pop_newtimef(EEG_integrals_am, 1,  channel, options.epoch_window_ms, options.cycles, 'baseline', options.epoch_window_baseline, 'plotersp', 'off', 'plotphasesign', 'off', 'plotitc', 'off', 'freqs',[12,30]);
        trials_nam = 0;
        P_nam = [];
        
        all_data{indx,1} = participant;
        all_data{indx,2} = PA;
        all_data{indx,3} = EEG_integrals_am.epoch;
        all_data{indx,4} = trials_am;
        all_data{indx,5} = trials_nam;
        all_data{indx,6} = timesout;
        all_data{indx,7} = freqs;
        all_data{indx,8} = channel;
        indx = indx+1;
    end
    % linear mod
    all_channels = all_data(strcmp(participant, [all_data(:,1)]), 2);
    all_channels_reshaped = cat(4, all_channels{:});
    % channel x time*freq x trials
    Y_1 = zeros(size(all_channels_reshaped,4), size(all_channels_reshaped,1)*size(all_channels_reshaped,2), size(all_channels_reshaped, 3));

    for pp_c=1:length(all_channels)
        x = all_channels{pp_c};
        Y_1(pp_c,:,:) = reshape(x, [size(x,1)*size(x,2), size(x,3)]);
    end

    eeg_epochs = all_data(strcmp(participant, [all_data(:,1)]), 3);
    [x_1] =  create_design_matrix_model(eeg_epochs{1});

    Y_1(:, :, any(isnan(x_1), 2)) = [];
    x_1(any(isnan(x_1), 2), :) = [];
    %     figure; imagesc(x_1);
    disp('train mod 1')
    model = {};
    for current_electrode = 1:size(Y_1, 1)
        Y_now = squeeze(Y_1(current_electrode, :, :))';
        model{current_electrode,1} = limo_glm(Y_now, x_1, 2, 0, 1, 'OLS', 'Time-Frequency', 0, size(Y_1,2));
    end
    ancova_models{indx_all, 1} = participant;
    ancova_models{indx_all, 2} = model;
    ancova_models{indx_all, 3} = x_1(:,3);
    indx_all = indx_all + 1;
end
end