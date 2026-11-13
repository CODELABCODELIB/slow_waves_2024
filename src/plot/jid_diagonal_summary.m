function [diag_vals, slope, abs_deriv, gridx] = jid_diagonal_summary(feature_jid, options)
%% Extract the diagonal of each JID and summarise its change along the diagonal
% The diagonal bins (1,1)...(50,50) are steady rhythms (ITI_k ~ ITI_k+1),
% going from fast (~32 ms) to slow (~100 s) intervals.
%
% **Usage:**
%   - [diag_vals, slope, abs_deriv, gridx] = jid_diagonal_summary(feature_jid)
%   - jid_diagonal_summary(... , 'min_bins', 5)
%
% Input(s):
%    feature_jid = cell {participant x channel} of 50x50 JIDs (empty cells allowed)
%
% Optional input parameter(s):
%    - MIN_H, MAX_H, BINS (Default 1.5, 5, 50) = JID grid, as in plot_jid / assign_tap2bin
%    - min_bins (Default 5) = minimal number of filled diagonal bins for slope/abs_deriv
%    - floor_value (Default -7) = values <= floor_value are treated as empty bins
%              (log10(0 + 1e-11) = -11 for empty rate bins, log10(0 + 1e-8) = -8 for latency)
%
% Output(s):
%   - diag_vals = participant x channel x BINS, diagonal values (NaN = empty bin)
%   - slope = participant x channel, least-squares slope of the diagonal values
%             vs gridx (feature units per log10 ms)
%   - abs_deriv = participant x channel, mean |delta value| / delta log10 ms between
%             consecutive filled diagonal bins (gaps are skipped)
%   - gridx = bin centres in log10 ms
%
arguments
    feature_jid cell;
    options.MIN_H = 1.5;
    options.MAX_H = 5;
    options.BINS = 50;
    options.min_bins = 5;
    options.floor_value = -7;
end
gridx = linspace(options.MIN_H, options.MAX_H, options.BINS);
[n_pp, n_chans] = size(feature_jid);
diag_vals = nan(n_pp, n_chans, options.BINS);
slope = nan(n_pp, n_chans);
abs_deriv = nan(n_pp, n_chans);
for pp=1:n_pp
    for chan=1:n_chans
        jid = feature_jid{pp,chan};
        if isempty(jid); continue; end
        if ~isequal(size(jid), [options.BINS options.BINS])
            error('jid_diagonal_summary:Size', 'JID of participant %d channel %d is %s, expected %dx%d', ...
                pp, chan, mat2str(size(jid)), options.BINS, options.BINS);
        end
        v = double(diag(jid))';
        v(~isfinite(v) | v <= options.floor_value) = NaN;
        diag_vals(pp,chan,:) = v;
        ok = ~isnan(v);
        if sum(ok) < options.min_bins; continue; end
        x = gridx(ok);
        y = v(ok);
        p = polyfit(x, y, 1);
        slope(pp,chan) = p(1);
        abs_deriv(pp,chan) = mean(abs(diff(y)) ./ diff(x));
    end
end
end
