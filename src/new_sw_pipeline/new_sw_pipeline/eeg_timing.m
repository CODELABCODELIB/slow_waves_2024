function output = eeg_timing(action, varargin)
%EEG_TIMING Early resampling and exact source-clock metadata.

switch action
    case 'downsample'
        output = downsample_for_speed(varargin{:});
    case 'map'
        output = resampling_time_map(varargin{:});
    case 'attach'
        output = add_slow_wave_times(varargin{:});
    otherwise
        error('swpipeline:TimingAction', 'Unknown timing action: %s', action);
end

end

function EEG = downsample_for_speed(EEG, working_srate)
%DOWNSAMPLE_FOR_SPEED Early antialias resampling; the analysis rate stays 128 Hz.

validateattributes(working_srate, {'numeric'}, {'scalar', 'positive', 'finite'});
rate = min(EEG.srate, working_srate);
if rate <= 96
    error('swpipeline:InvalidWorkingRate', 'The working rate must support the 48-Hz filter.');
end
source = struct('srate', EEG.srate, 'pnts', EEG.pnts);
if isfield(EEG, 'event')
    source.event = EEG.event;
end
if rate < EEG.srate
    fprintf('Speed-up: resampling working data %.1f -> %.1f Hz.\n', EEG.srate, rate);
    EEG = pop_resample(EEG, rate);
    EEG = eeg_checkset(EEG);
end
if ~isfield(EEG, 'etc') || isempty(EEG.etc)
    EEG.etc = struct();
end
EEG.etc.source_resampling_map = resampling_time_map(source, EEG.srate, EEG.pnts);

end

function mapping = resampling_time_map(EEG, output_srate, output_pnts)
%RESAMPLING_TIME_MAP Map resampled positions to the common working-data clock.

validateattributes(output_srate, {'numeric'}, {'scalar', 'positive', 'finite'});
validateattributes(output_pnts, {'numeric'}, {'scalar', 'integer', 'positive'});
boundaries = [];
if isfield(EEG, 'event') && ~isempty(EEG.event)
    indices = eeg_findboundaries(EEG.event);
    boundaries = [EEG.event(indices).latency];
    boundaries = boundaries(isfinite(boundaries) & boundaries > 0 & boundaries <= EEG.pnts);
    fractional = mod(boundaries, 1) ~= 0;
    boundaries(fractional) = round(boundaries(fractional) + 0.5);
end
input_bounds = unique([1, boundaries, EEG.pnts + 1]);
[numerator, denominator] = rat(output_srate / EEG.srate, 1e-12);
lengths = ceil(diff(input_bounds) * numerator / denominator);
output_bounds = [1, 1 + cumsum(lengths)];
if output_bounds(end) ~= output_pnts + 1
    error('swpipeline:TimeMapping', ...
        'Resampled length differs from the segment-based map; timing alignment is unsafe.');
end
mapping.input_bounds = input_bounds;
mapping.output_bounds = output_bounds;
mapping.input_srate = EEG.srate;
mapping.output_srate = output_srate;
mapping.output_pnts = output_pnts;

end

function results = add_slow_wave_times(results, mapping, source_mapping, source_xmin)
%ADD_SLOW_WAVE_TIMES Exact peak times and segment IDs on the source-data clock.

results.time_mapping = mapping;
results.source_time_mapping = source_mapping;
results.source_xmin = source_xmin;
for ch = 1:numel(results.channels)
    channel = results.channels(ch);
    peaks = double([channel.maxnegpk_input{:}]);
    positions = nan(size(peaks));
    segment_ids = zeros(size(peaks));
    for segment = 1:(numel(mapping.output_bounds) - 1)
        inside = peaks >= mapping.output_bounds(segment) & ...
            peaks < mapping.output_bounds(segment + 1);
        positions(inside) = mapping.input_bounds(segment) + ...
            (peaks(inside) - mapping.output_bounds(segment)) * ...
            mapping.input_srate / mapping.output_srate;
        segment_ids(inside) = segment;
    end
    results.channels(ch).maxnegpk_seconds = num2cell(source_xmin + ...
        sample_times_from_map(source_mapping, positions));
    results.channels(ch).segment_index = num2cell(segment_ids);
end

end

function times = sample_times_from_map(mapping, positions)
%SAMPLE_TIMES_FROM_MAP Working-recording seconds; positions are one-based.

positions = double(positions);
times = nan(size(positions));
for segment_idx = 1:(numel(mapping.output_bounds) - 1)
    inside = positions >= mapping.output_bounds(segment_idx) & ...
        positions < mapping.output_bounds(segment_idx + 1);
    times(inside) = (mapping.input_bounds(segment_idx) - 1) / mapping.input_srate + ...
        (positions(inside) - mapping.output_bounds(segment_idx)) / mapping.output_srate;
end
if any(~isfinite(times(:)))
    error('swpipeline:ComparisonSampleOutsideMap', 'Signal or peak position is outside its map.');
end

end
