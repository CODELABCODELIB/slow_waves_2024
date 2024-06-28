function [selected_2] = select_from_status_2(all_set_files)
%% select participants where there is BS data and alignment were successful
%
% **Usage:** [selected_2] = select_from_status_2(all_set_files)
%
%  Input(s):
%   - all_set_files = cell based on status_2.mat file containing meta data of
%   the EEG measurement. Specifically whether BS data is present and 
%   whether participant's data was aligned 
%
%  Output(s):
%   - selected_2 = file names for selected participants
%
% Author: R.M.D. Kock
% 

selected_2 = all_set_files(1,[all_set_files{2,:}] & [all_set_files{3,:}]);
end
