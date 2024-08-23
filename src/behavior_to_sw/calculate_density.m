function [density] = calculate_density(twa,options)
%% Calculate the density (number of slow waves) over the whole recording per electrode
%
% **Usage:**
%   - [density] = calculate_density(twa)
%                 - calculate_density(...,'sel_field', "poszx")
%
% Input(s):
%    twa = slow waves struct results (twa_results.channels)
%
% Optional input parameter(s):
%    sel_field (default: "negzx") = field in twa to calculate the length of
%
% Output(s):
%    densities = The total density for the whole recording
%
% Ruchella Kock, Leiden University, 17/01/2024
%
arguments
    twa
    options.sel_field = "negzx";
end
twa_cell = struct2cell(twa');
fields = fieldnames(twa);
density = cellfun(@(data,datalength) length(data)/(datalength/128/60),twa_cell(strcmp(fields',options.sel_field),:),twa_cell(strcmp(fields','datalength'),:));
end