function plot_ocular_event_snippets_sw(filtered_data, srate, onsets_struct, save_dir, base_name, options)
%% Save one event-locked sanity-check plot per ocular event derivation
%
% **Usage:** plot_ocular_event_snippets_sw(filtered_data, srate, onsets_struct, save_dir, base_name)
%   - plot_ocular_event_snippets_sw(..., 'pre_ms', -500, 'post_ms', 500)
%
% For each named field in onsets_struct (e.g. all/right_vertical/left_vertical/
% horizontal), cuts and averages event-locked snippets across all channels of
% filtered_data, and saves one PNG per field -- so each ocular-event type gets
% its own readable plot instead of one figure mixing every event type together.
%
%  Input(s):
%   - filtered_data = [chans x samples] continuous data (e.g. train_ica_opticat_sw's
%     filtered_data output)
%   - srate = sampling rate of filtered_data, in Hz
%   - onsets_struct = struct whose fields are named onset sample-index vectors
%     (e.g. struct('all', event_onsets, 'right_vertical', ..., 'horizontal', ...))
%   - save_dir = directory to save PNGs into (must already exist)
%   - base_name = filename prefix (e.g. the .set file's base name)
%   - options.pre_ms **optional** double = window start relative to onset, ms
%     (default -300 -- wider than the actual overweighting window, for visual context)
%   - options.post_ms **optional** double = window end relative to onset, ms (default 300)
%
%  Output(s):
%   - Saved PNGs: <save_dir>/opticat_<base_name>_sanity_<field>.png, one per
%     onsets_struct field with at least one usable event
%
% Requires:
%   - extract_event_snippets_sw
%
% Author: R.M.D. Kock, Leiden University

arguments
    filtered_data double;
    srate (1,1) double;
    onsets_struct struct;
    save_dir char;
    base_name char;
    options.pre_ms (1,1) double = -300;
    options.post_ms (1,1) double = 300;
end

field_names = fieldnames(onsets_struct);

for f = 1:length(field_names)
    name = field_names{f};
    onsets = onsets_struct.(name);

    [segments, n_used] = extract_event_snippets_sw(filtered_data, onsets, srate, ...
        options.pre_ms, options.post_ms);

    if n_used == 0
        fprintf('plot_ocular_event_snippets_sw: skipping %s (no usable events)\n', name);
        continue
    end

    avg_segment = mean(segments, 3);

    fig = figure('Visible', 'off');
    plot(avg_segment');
    title(sprintf('%s: %s (n=%d events)', base_name, name, n_used), 'Interpreter', 'none');
    xlabel('Samples relative to event window start');
    ylabel('\muV');
    saveas(fig, sprintf('%s/opticat_%s_sanity_%s.png', save_dir, base_name, name));
    close(fig);
end

end
