function EEG = prepare_channels(EEG, labels_to_remove, interpolate)
%PREPARE_CHANNELS Remove channels/templates, then optionally interpolate scalp.

remove_idx = find(ismember({EEG.chanlocs.labels}, labels_to_remove));
if ~isempty(remove_idx)
    EEG = pop_select(EEG, 'nochannel', remove_idx);
    EEG = eeg_checkset(EEG);
    fprintf('Removed channels: %s.\n', strjoin(labels_to_remove, ', '));
end
template_fields = {'Orignalchanlocs', 'Originalchanlocs'};
for k = 1:numel(template_fields)
    name = template_fields{k};
    if isfield(EEG, name) && ~isempty(EEG.(name))
        template = EEG.(name);
        EEG.(name) = template(~ismember({template.labels}, labels_to_remove));
    end
end
if ~interpolate
    return;
end
for k = 1:numel(template_fields)
    name = template_fields{k};
    if isfield(EEG, name) && ~isempty(EEG.(name))
        EEG = pop_interp(EEG, EEG.(name), 'spherical');
        EEG = eeg_checkset(EEG);
        return;
    end
end
warning('swpipeline:MissingChannelTemplate', ...
    'No original channel locations available. Interpolation skipped.');

end
