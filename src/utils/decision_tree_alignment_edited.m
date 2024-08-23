function [EEG, simple,delay_model] = decision_tree_alignment_edited(EEG, BS, participant_selection);
%% Decides when to choose the model based alignment, BS based alignment, or old alignment
%
% **Usage:** [EEG simple] = decision_tree_alignment(EEG, BS, create_diagnostic_plot)
%
%
% Input(s):
%   - EEG = EEG data from one participant
%   - BS = preprocessed BS dataset
%   - create_diagnostic_plot =  bool 1= yes create diagnostic plot, 0 = do not create plot
%
% Output(s):
%   - EEG = EEG data from one participant where EEG.Aligned.Phone.Blind contains corrected alignment rules
%   - simple = 1: model based alignment , 0 = no alignment empty field returned
%
% Author: R.M.D. Kock

%%
if isfield(EEG.Aligned.BS, 'Data') && isfield(EEG.Aligned.BS, 'Model')
    
    display ('BS and BSNET model are present')
    rule3 = 0;
    
    % examine blind alignment
    [Phone, Transitions, idx] = get_phone_data(EEG, 0);
    
    ep_blind_bs = getepocheddata(nanzscore(BS),idx,[-30000 30000]); %ep_blind_bs(ep_blind_bs==0) = deal(NaN);
    ep_blind_model = getepocheddata(nanzscore(EEG.Aligned.BS.Model),idx,[-30000 30000]); %ep_blind_model(ep_blind_model==0) = deal(NaN);
    [max_val_model, max_model_loc]= max((mean(ep_blind_model, 'omitnan')));
    [max_val_bs, max_bs_loc]= max((abs(mean(ep_blind_bs, 'omitnan'))));
    
    %Phone data is ahead by the following number of samples according to model
    delay_model = max_model_loc-30000;
    delay_bs = max_bs_loc-30000;
    differences_bs = NaN;
    
    if participant_selection
        if (max_val_bs< 0.1630 || abs(diff([delay_model delay_bs]))>EEG.srate)
            for ff = 1:size(EEG.Aligned.Phone.Blind,2)
                %EEG.Aligned.Phone.Model{1,ff} = EEG.Aligned.Phone.Blind{1,ff};
                EEG.Aligned.Phone.Model{1,ff} = [];
            end
            simple = 0;
            %elseif (abs(diff([delay_model delay_bs]))<500)
        else
            for ff = 1:size(EEG.Aligned.Phone.Blind,2)
                EEG.Aligned.Phone.Model{1,ff} = EEG.Aligned.Phone.Blind{1,ff};
                EEG.Aligned.Phone.Model{1,ff}(:,2) = EEG.Aligned.Phone.Model{1,ff}(:,2)+delay_model;
            end
            simple = 1;
            
            % check difference between peak prominance after alignment
            [Phone, Transitions, idx] = get_phone_data(EEG, 2);
            [simple_prominance,differences_bs] = decision_peak_prominance(mean(getepocheddata(nanzscore(EEG.Aligned.BS.Model),idx,[-3000 3000]), 'omitnan'));
            if simple_prominance == 0
                rule3 = rule3 +1;
                for ff = 1:size(EEG.Aligned.Phone.Blind,2)
                    %EEG.Aligned.Phone.Model{1,ff} = EEG.Aligned.Phone.Blind{1,ff};
                    EEG.Aligned.Phone.Model{1,ff} = [];
                end
                simple = 0;
            end
            %else
            %    for ff = 1:size(EEG.Aligned.Phone.Blind,2)
            %        EEG.Aligned.Phone.Model{1,ff} = EEG.Aligned.Phone.Blind{1,ff};
            %       EEG.Aligned.Phone.Model{1,ff}(:,2) = EEG.Aligned.Phone.Model{1,ff}(:,2)+delay_bs;
            %   end
            %    simple = 2;
        end
    else
        for ff = 1:size(EEG.Aligned.Phone.Blind,2)
            EEG.Aligned.Phone.Model{1,ff} = EEG.Aligned.Phone.Blind{1,ff};
            EEG.Aligned.Phone.Model{1,ff}(:,2) = EEG.Aligned.Phone.Model{1,ff}(:,2)+delay_model;
        end
        simple = 1; 
    end
else
    for ff = 1:size(EEG.Aligned.Phone.Blind,2)
        EEG.Aligned.Phone.Model{1,ff} = EEG.Aligned.Phone.Blind{1,ff};
        EEG.Aligned.Phone.Model{1,ff} = [];
    end
    simple =0;   
end