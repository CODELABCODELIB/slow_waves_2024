function [eeg_name] = calculate_date_differences(eeg_name)
%% Calculates the difference between all dates and smallest date
% This function is used to ignore the second file of curfew
% participants(ignore the data after curfew)
%
% **Usage:** [eeg_name] = calculate_date_differences(eeg_name)
%
% Input(s):
%   - eeg_name = loaded status.mat for one participant
%
% Output(s):
%   - eeg_name =  status.mat with new field datediff
%
% Author: R.M.D. Kock, Leiden University

%%
smallest_date = datetime(min(cell2mat({eeg_name.start})), 'ConvertFrom', 'epochtime', 'Format', 'dd-MM-yy');
date_diff = cellfun(@(x) between(datetime(x,'ConvertFrom', 'epochtime'), smallest_date, 'days'), {eeg_name.start}, 'UniformOutput', false);
split_diff = cellfun(@(z) split(z, {'days'}), date_diff);
date_diff = num2cell(split_diff);
[eeg_name.datediff] = date_diff{:};
end
