function derivations = resolve_ocular_derivations(EEG, options)
%RESOLVE_OCULAR_DERIVATIONS Resolve source indices before changing channels.
%   Call immediately after loading the original dataset. The resulting label
%   definitions remain valid after technical channels are removed.
%   As in the original pipeline (gettechnicallycleanEEG_sw), configured EOG
%   channels that were removed as bad are skipped. A derivation left without a
%   positive or negative channel is dropped; at least one must remain.

labels = {EEG.chanlocs.labels};
if numel(unique(labels)) ~= numel(labels) || any(cellfun('isempty', labels))
    error('swpipeline:AmbiguousChannelLabels', ...
        'Refined correction requires nonempty, unique channel labels.');
end

names = {'VEOG', 'HEOG'};
positive = {options.veog_positive, options.heog_positive};
negative = {options.veog_negative, options.heog_negative};
derivations = struct('name', names, 'positive_labels', {{}, {}}, ...
    'negative_labels', {{}, {}});
keep = true(1, 2);
for derivation_idx = 1:2
    derivations(derivation_idx).positive_labels = ...
        resolve_group(positive{derivation_idx}, labels);
    derivations(derivation_idx).negative_labels = ...
        resolve_group(negative{derivation_idx}, labels);
    if isempty(derivations(derivation_idx).positive_labels) || ...
            isempty(derivations(derivation_idx).negative_labels)
        warning('swpipeline:DroppedEOGDerivation', ...
            '%s skipped: no positive or no negative channel left in the dataset.', ...
            names{derivation_idx});
        keep(derivation_idx) = false;
        continue;
    end
    if ~isempty(intersect(derivations(derivation_idx).positive_labels, ...
            derivations(derivation_idx).negative_labels))
        error('swpipeline:OverlappingEOGChannels', ...
            'Positive and negative groups for %s must not overlap.', names{derivation_idx});
    end
    fprintf('%s = mean(%s) - mean(%s).\n', names{derivation_idx}, ...
        strjoin(derivations(derivation_idx).positive_labels, ', '), ...
        strjoin(derivations(derivation_idx).negative_labels, ', '));
end
derivations = derivations(keep);
if isempty(derivations)
    error('swpipeline:MissingEOGChannel', ...
        'None of the configured EOG derivations can be formed from the loaded dataset.');
end

end

function selected_labels = resolve_group(selection, labels)
if isnumeric(selection)
    validateattributes(selection, {'numeric'}, ...
        {'vector', 'nonempty', 'integer', 'positive', 'finite', '<=', numel(labels)});
    selected_labels = labels(selection(:)');
elseif iscellstr(selection) || isstring(selection) || ischar(selection)
    if iscell(selection)
        selected_labels = selection;
    else
        selected_labels = cellstr(selection);
    end
    selected_labels = selected_labels(:)';
    if isempty(selected_labels)
        error('swpipeline:InvalidEOGDefinition', 'An EOG group must not be empty.');
    end
    missing = ~ismember(selected_labels, labels);
    if any(missing)
        warning('swpipeline:DroppedEOGChannel', ...
            'EOG channel(s) %s not in the dataset (removed as bad); using the remaining ones.', ...
            strjoin(selected_labels(missing), ', '));
        selected_labels = selected_labels(~missing);
    end
else
    error('swpipeline:InvalidEOGDefinition', ...
        'EOG groups must contain original channel indices or channel labels.');
end
if numel(unique(selected_labels)) ~= numel(selected_labels)
    error('swpipeline:DuplicateEOGChannel', 'An EOG group contains a duplicate channel.');
end
end
