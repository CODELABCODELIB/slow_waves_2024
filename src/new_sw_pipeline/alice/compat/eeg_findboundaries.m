function boundaries = eeg_findboundaries(EEG)
%EEG_FINDBOUNDARIES Indices of boundary events (fallback for EEGLAB <= 2020).
%   Only added to the path by run_sw_pipeline_alice.m when EEGLAB has no
%   eeg_findboundaries of its own. Accepts an EEG struct or its event array.

if isfield(EEG, 'event')
    events = EEG.event;
else
    events = EEG;
end
boundaries = [];
if isempty(events) || ~isfield(events, 'type')
    return;
end
types = {events.type};
is_text = cellfun(@ischar, types);
is_boundary = false(size(types));
is_boundary(is_text) = strcmpi(types(is_text), 'boundary');
is_boundary(~is_text) = cellfun(@(type) isnumeric(type) && isscalar(type) && type == -99, ...
    types(~is_text));
boundaries = find(is_boundary);

end
