function [amp] = calculate_p2p_amplitude(twa,options)
%% Calculate the (median) peak to peak (p2p) amplitude per  per channel
%
% **Usage:**
%   - [amp] = calculate_p2p_amplitude(twa)
%           - calculate_p2p_amplitude(...,'sel_field_pos', "maxampwn")
%           - calculate_p2p_amplitude(...,'sel_field_neg', "minampwn")
%
% Input(s):
%    twa = slow waves struct results (twa_results.channels)
%
% Optional input parameter(s):
%    sel_field_pos (default: "maxpospkamp") = The amplitude of the largest
%           positive peak
%    sel_field_neg (default: "maxnegpkamp") =  The amplitude of the largest
%           negative peak
%
% Output(s):
%    amp = The median peak to peak density
%
% Ruchella Kock, Leiden University, 17/01/2024
%
arguments
    twa
    options.sel_field = "maxpospkamp";
    options.pool_method = 'median';
end
if contains('maxpospkamp','pos')
    sel_field_pos = options.sel_field;
    sel_field_neg = replace(options.sel_field, 'pos', 'neg');
elseif contains('maxpospkamp','neg')
    sel_field_neg = options.sel_field;
    sel_field_pos = replace(options.sel_field, 'neg', 'pos');
end

twa_cell = struct2cell(twa');
fields = fieldnames(twa);
if strcmp(options.pool_method, 'median')
    amp = cellfun(@(maxamp_ch,minamp_ch) median(cellfun(@(maxamp_wv,minamp_wv) maxamp_wv-minamp_wv,maxamp_ch,minamp_ch)),twa_cell(find(strcmp(fields',sel_field_pos)),:),twa_cell(find(strcmp(fields',sel_field_neg)),:));
elseif strcmp(options.pool_method, 'none')
    amp = cellfun(@(maxamp_ch,minamp_ch) cellfun(@(maxamp_wv,minamp_wv) maxamp_wv-minamp_wv,maxamp_ch,minamp_ch),twa_cell(find(strcmp(fields',sel_field_pos)),:),twa_cell(find(strcmp(fields',sel_field_neg)),:),'UniformOutput',false);
end
end