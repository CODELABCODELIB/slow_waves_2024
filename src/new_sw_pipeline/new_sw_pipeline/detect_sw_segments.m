function results = detect_sw_segments(data, orig_fs, thramp, segments)
%DETECT_SW_SEGMENTS Apply the original detector independently inside boundaries.

validateattributes(segments, {'numeric'}, {'real', 'finite', 'integer', 'positive', 'ncols', 2});
if isempty(segments) || segments(1, 1) ~= 1 || segments(end, 2) ~= size(data, 2) || ...
        any(segments(:, 2) < segments(:, 1)) || ...
        any(segments(2:end, 1) ~= segments(1:end-1, 2) + 1)
    error('swpipeline:DetectionSegments', 'Segments must partition the input samples.');
end
results = [];
position_fields = {'negzx', 'poszx', 'wvend', 'maxnegpk', 'maxpospk', 'negpks', 'pospks'};
for k = 1:size(segments, 1)
    offset = segments(k, 1) - 1;
    part = twalldetectnew_TA_v4(data(:, segments(k, 1):segments(k, 2)), orig_fs, thramp);
    if isempty(results)
        results = part;
        for ch = 1:numel(results.channels)
            fields = fieldnames(results.channels(ch));
            for f = 1:numel(fields)
                if iscell(results.channels(ch).(fields{f}))
                    results.channels(ch).(fields{f}) = {};
                end
            end
            results.channels(ch).datalength = size(data, 2);
        end
    end
    for ch = 1:numel(part.channels)
        channel = part.channels(ch);
        for f = 1:numel(position_fields)
            name = position_fields{f};
            exact = [name, '_input'];
            for wi = 1:numel(channel.(exact))
                channel.(exact){wi} = channel.(exact){wi} + offset;
                scaled = round(single(channel.(exact){wi}) / 128 * orig_fs);
                if ismember(name, {'negpks', 'pospks'})
                    channel.(name){wi} = {scaled};
                else
                    channel.(name){wi} = scaled;
                end
            end
        end
        fields = fieldnames(channel);
        for f = 1:numel(fields)
            if iscell(channel.(fields{f}))
                results.channels(ch).(fields{f}) = ...
                    [results.channels(ch).(fields{f}), channel.(fields{f})];
            end
        end
    end
end
results.continuous_segments = segments;

end
