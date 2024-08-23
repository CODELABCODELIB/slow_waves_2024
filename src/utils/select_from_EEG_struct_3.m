function [select_3] = select_from_EEG_struct_3(EEG)
%% Select participants with no saving error and attys is false
%
% **Usage:**  [select_3] = select_from_EEG_struct_3(EEG)
%
%  Input(s):
%   - EEG = EEG struct
%
%  Output(s):
%   - select_3 = logical 1 select EEG struct, 0 otherwise
%
% Author: R.M.D. Kock

    select_3 = mod(size(EEG.data,2), EEG.pnts) == 0 && ~(EEG.Attys);
end