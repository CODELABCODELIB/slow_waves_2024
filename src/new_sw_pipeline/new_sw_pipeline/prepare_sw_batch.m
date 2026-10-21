function [files, ids] = prepare_sw_batch(config)
%PREPARE_SW_BATCH Resolve the batch and reject ambiguous output IDs.

files = config.dataset_files;
if isempty(files)
    listing = dir(fullfile(config.input_directory, config.file_pattern));
    listing = listing(~[listing.isdir]);
    files = arrayfun(@(entry) fullfile(entry.folder, entry.name), ...
        listing, 'UniformOutput', false);
elseif isstring(files)
    files = cellstr(files);
end
if ~iscellstr(files) || isempty(files)
    error('swpipeline:NoDatasets', 'Specify dataset_files or a folder containing .set files.');
end
files = files(:)';
ids = cell(size(files));
for k = 1:numel(files)
    if exist(files{k}, 'file') ~= 2
        error('swpipeline:MissingDataset', 'Dataset not found: %s', files{k});
    end
    [folder, name, extension] = fileparts(files{k});
    if ~strcmpi(extension, '.set')
        error('swpipeline:DatasetExtension', 'Expected an EEGLAB .set file: %s', files{k});
    end
    if isempty(folder)
        files{k} = fullfile(pwd, files{k});
    end
    ids{k} = name;
end
if ~isempty(config.dataset_ids)
    ids = config.dataset_ids;
    if ischar(ids) || isstring(ids)
        ids = cellstr(ids);
    end
    if ~iscellstr(ids)
        error('swpipeline:DatasetIDs', 'dataset_ids must contain text entries.');
    end
    ids = ids(:)';
    if numel(ids) ~= numel(files)
        error('swpipeline:DatasetIDs', 'dataset_ids must have one entry per dataset.');
    end
end
if any(cellfun('isempty', ids)) || numel(unique(lower(string(ids)))) ~= numel(ids) || ...
        any(cellfun(@(id) isempty(regexp(id, '^[A-Za-z0-9][A-Za-z0-9_.-]*$', 'once')), ids))
    error('swpipeline:DatasetIDs', ...
        'Use unique IDs containing letters, digits, underscores, dots, or hyphens.');
end
if numel(unique(string(files))) ~= numel(files)
    error('swpipeline:DuplicateDataset', 'A dataset is listed more than once.');
end

validate_batch_settings(config, ids);

end

function validate_batch_settings(config, ids)
%VALIDATE_BATCH_SETTINGS Check mode switches and per-dataset lists.

count = numel(ids);
if ~ismember(config.ocular_method, {'old', 'refined'}) || ...
        ~ismember(config.refined_ica_mode, {'auto', 'reuse', 'train'})
    error('swpipeline:InvalidMode', 'Check ocular_method and refined_ica_mode.');
end
flags = {'enable_speedup', 'continue_on_error', 'save_topoplots', ...
    'show_topoplots', 'save_preprocessed_EEG', 'save_cleaned_EEG'};
for k = 1:numel(flags)
    validateattributes(config.(flags{k}), {'logical'}, {'scalar'});
end
lists = {'manual_ica_reject_comps', 'ica_report_files'};
for k = 1:numel(lists)
    value = config.(lists{k});
    if ~iscell(value) || (~isempty(value) && numel(value) ~= count)
        error('swpipeline:BatchListLength', '%s must have one cell per dataset.', lists{k});
    end
end
paths = cell(1, count);
for k = 1:count
    paths{k} = fullfile(config.ica_cache_directory, [ids{k}, '_refined_ica.mat']);
    if ~isempty(config.ica_report_files) && ~isempty(config.ica_report_files{k})
        paths{k} = config.ica_report_files{k};
    end
    if ~ischar(paths{k}) || ~isrow(paths{k})
        error('swpipeline:ICAReportPath', 'ICA report paths must be character vectors.');
    end
    [~, ~, extension] = fileparts(paths{k});
    if ~strcmpi(extension, '.mat')
        error('swpipeline:ICAReportPath', 'ICA cache files must have the .mat extension.');
    end
end
if ~iscellstr(paths) || numel(unique(lower(string(paths)))) ~= numel(paths)
    error('swpipeline:SharedICACache', 'Use a separate ICA report path for each dataset.');
end

end
