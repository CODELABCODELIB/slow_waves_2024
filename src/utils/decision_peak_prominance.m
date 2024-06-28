function [simple,differences_bs] = decision_peak_prominance(epoched_model_predictions)
%% Participant selection based on the difference between the aligned largest peak and second largest peak
%
% **Usage:** [simple, differences_bs] = decision_peak_prominance(epoched_model_predictions)
%
%
% Input(s):
%   - epoched_model_predictions = epoched model predictions timelocked to aligned taps
%
% Output(s):
%   - simple = 1: participant kept , 0 = participant rejected
%   - differences_bs = difference between the largest peak and second largest peak
%
% Author: R.M.D. Kock

%%
if ~isempty(epoched_model_predictions) & sum(isnan(epoched_model_predictions)) ~= 6001
    simple = 1;
    f = fit([-3000:3000].', epoched_model_predictions.', 'smoothingspline', 'SmoothingParam', 0.01);
    mean_model = f([-3000:3000].');
    [pks_mod, locs_mod, w_mod, prominance] = findpeaks(mean_model, 'MinPeakWidth', 100);
    sorted_p = sort(prominance);
    differences_bs = sorted_p(end) - sorted_p(end-1);
    if differences_bs < 0.15
        simple = 0;
    end
else
    differences_bs = NaN;
    simple = 0;
end
end
