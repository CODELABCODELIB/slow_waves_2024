function [slope] = calculate_slope(twa,options)
%% Calculate the median upwards or downwards slope over the whole recording per electrode
%
% **Usage:**
%   - [slope] = calculate_slope(twa)
%               - calculate_slope(...,'sel_field', "mxdnslp")
%
% Input(s):
%    twa = slow waves struct results (twa_results.channels)
%
% Optional input parameter(s):
%    sel_field (default: "mxdnslp") = field in twa to calculate the length of
%       note default is downwards slope, cal the function with 
%       sel_field = 'mxupslp' for upwards slope
%
% Output(s):
%    slope = The upwards or downwards slope
%
% Ruchella Kock, Leiden University, 17/01/2024
%
arguments
    twa
    options.sel_field = "mxdnslp";
    options.pool_method = 'median'
end
twa_cell = struct2cell(twa');
fields = fieldnames(twa);
if strcmp(options.pool_method, 'median')
    slope = cellfun(@(chan) median(cell2mat(chan)),twa_cell(strcmp(fields',options.sel_field),:));
elseif strcmp(options.pool_method, 'none')
    slope = cellfun(@(chan) cell2mat(chan),twa_cell(strcmp(fields',options.sel_field),:),'UniformOutput',false);
end
end