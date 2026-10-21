function [EEG, rejected, report] = remove_refined_ocular_artifacts( ...
    EEG, derivations, config, dataset)
%REMOVE_REFINED_OCULAR_ARTIFACTS Refined correction, per-dataset ICA cache and QC.

[options, cache_file] = refined_ica_options_for_dataset(config, dataset.id, dataset.index);
[EEG, rejected, report] = correct_refined_ocular_data( ...
    EEG, derivations, {'E63', 'E64'}, options);
report.dataset_id = dataset.id;
report.source_file = dataset.source_file;
if ~report.ica_reused
    save_refined_ica_cache(report, cache_file);
end
save_refined_ocular_report(report, fullfile(dataset.directory, 'Ocular_QC'));

end

function [EEG, rejected_components, report] = correct_refined_ocular_data( ...
    EEG, derivations, ocular_labels, options)
%REMOVE_REFINED_OCULAR_ARTIFACTS Train/reuse ICA and apply to broadband EEG.

defaults = refined_ocular_defaults;
if nargin < 4
    options = defaults;
else
    fields = fieldnames(defaults);
    for field_idx = 1:numel(fields)
        if ~isfield(options, fields{field_idx})
            options.(fields{field_idx}) = defaults.(fields{field_idx});
        end
    end
end
validate_options(options);
if EEG.trials ~= 1
    error('swpipeline:ContinuousDataRequired', 'Refined correction expects continuous EEG.');
end
validateattributes(EEG.data, {'single', 'double'}, {'2d', 'real', 'nonempty'});
for first = 1:options.chunk_samples:EEG.pnts
    block = EEG.data(:, first:min(first + options.chunk_samples - 1, EEG.pnts));
    if any(~isfinite(block(:)))
        error('swpipeline:NonfiniteICAData', ...
            'Refined correction requires finite EEG before filtering and ICA.');
    end
end
clear block;

total_clock = tic;
stage_clock = tic;
analysis = clear_ica(EEG);
if analysis.srate > options.training_srate
    analysis = pop_resample(analysis, options.training_srate);
end
analysis = eeg_checkset(analysis);
effective_lowpass = min(options.eog_lowpass_hz, 0.45 * analysis.srate);
if options.training_highpass_hz >= effective_lowpass || ...
        options.slow_band_hz(2) >= effective_lowpass
    error('swpipeline:InvalidRefinedRates', ...
        'The assessment rate must support both the ICA high-pass and target band.');
end
fprintf('Refined ocular correction: assessment/training copy at %.1f Hz.\n', analysis.srate);
fprintf('EOG broadband: low-pass %.1f Hz; slow band %.2f-%.2f Hz.\n', ...
    effective_lowpass, options.slow_band_hz);

broad_guard = 0;
notch_applied = false;
if options.apply_mains_notch
    low_edge = options.mains_hz - options.notch_halfwidth_hz;
    high_edge = options.mains_hz + options.notch_halfwidth_hz;
    if low_edge > 0 && high_edge < analysis.srate / 2
        [analysis, ~, coefficients] = pop_eegfiltnew(analysis, ...
            'locutoff', low_edge, 'hicutoff', high_edge, 'revfilt', 1);
        broad_guard = broad_guard + ceil((numel(coefficients) - 1) / 2);
        notch_applied = true;
    else
        warning('swpipeline:NotchAboveNyquist', ...
            'The requested EOG notch is outside the available band; it was skipped.');
    end
end
[analysis, ~, coefficients] = pop_eegfiltnew(analysis, 'hicutoff', effective_lowpass);
broad_guard = broad_guard + ceil((numel(coefficients) - 1) / 2);
analysis = eeg_checkset(analysis);
segments = continuous_sample_segments(analysis);
derivation_matrix = ocular_derivation_matrix(analysis.chanlocs, derivations);
signals = zeros(numel(derivations), analysis.pnts);
for first = 1:options.chunk_samples:analysis.pnts
    samples = first:min(first + options.chunk_samples - 1, analysis.pnts);
    signals(:, samples) = derivation_matrix * double(analysis.data(:, samples));
end
events = detect_ocular_events(signals, analysis.srate, segments, ...
    options.event_window_sec, options.event_threshold_sd);
clear signals;
for derivation_idx = 1:numel(events)
    fprintf('  %s detections at %.2f SD: %d.\n', derivations(derivation_idx).name, ...
        options.event_threshold_sd, numel(events(derivation_idx).onsets));
end
report.timing.eog_preparation = toc(stage_clock);

%% Load a prior full solution or fit new ICA on a high-pass training copy.

stage_clock = tic;
report.ica_reused = options.reuse_ica;
report.ica_source_report = '';
report.timing.ica_loading = 0;
ica_indices = find(~ismember({analysis.chanlocs.labels}, ocular_labels));
if numel(ica_indices) < 2
    error('swpipeline:TooFewICAChannels', 'ICA needs at least two scalp channels.');
end
if options.reuse_ica
    [solution, cached_report] = load_refined_ica_report( ...
        options.ica_report_file, analysis, derivations, ica_indices, options);
    unmixing = double(solution.icaweights) * double(solution.icasphere);
    data_rank = cached_report.training_rank;
    report.ica_source_report = options.ica_report_file;
    report.timing.ica_loading = toc(stage_clock);
    report.timing.ica_training = 0;
    fprintf('Reusing full refined ICA (%d components); ICA training skipped.\n%s\n', ...
        size(unmixing, 1), options.ica_report_file);
else
    training = analysis;
    [training, ~, coefficients] = pop_eegfiltnew(training, ...
        'locutoff', options.training_highpass_hz);
    training_guard = broad_guard + ceil((numel(coefficients) - 1) / 2);
    training_valid = guarded_samples(segments, training.pnts, training_guard);
    training_covariance = signal_covariance_chunked( ...
        training.data, training_valid, options.chunk_samples);
    eigenvalues = eig(training_covariance(ica_indices, ica_indices));
    data_rank = sum(eigenvalues > max(eigenvalues) * options.rank_relative_tolerance);
    if data_rank < 2
        error('swpipeline:InsufficientICARank', 'The ICA training data have rank below two.');
    end
    ica_options = {};
    if data_rank < numel(ica_indices)
        ica_options = {'pca', data_rank};
    end
    algorithm = lower(char(options.ica_algorithm));
    switch algorithm
        case 'runica'
            ica_options = [ica_options, ...
                {'extended', 1, 'interrupt', 'off', 'rndreset', 0}];
        case 'picard'
            if exist('picard', 'file') ~= 2
                error('swpipeline:MissingPicard', ...
                    'Install the EEGLAB Picard plugin or select ica_algorithm ''runica''.');
            end
            ica_options = [ica_options, {'mode', 'standard', 'maxiter', 500}];
    end
    fprintf('Training %s ICA on a %.1f-Hz high-pass copy: %d scalp channels, rank %d.\n', ...
        algorithm, options.training_highpass_hz, numel(ica_indices), data_rank);
    random_state = rng;
    random_cleanup = onCleanup(@() rng(random_state));
    rng(options.random_seed, 'twister');
    training = pop_runica(training, 'icatype', algorithm, ...
        'chanind', ica_indices, 'options', ica_options);
    clear random_cleanup;
    if isempty(training.icaweights) || isempty(training.icasphere) || ...
            ~isequal(training.icachansind(:)', ica_indices(:)')
        error('swpipeline:RefinedICAFailed', ...
            'ICA did not return the expected scalp-channel solution.');
    end
    solution.icaweights = training.icaweights;
    solution.icasphere = training.icasphere;
    solution.icachansind = ica_indices;
    unmixing = double(solution.icaweights) * double(solution.icasphere);
    if any(~isfinite(unmixing(:))) || size(unmixing, 1) < 2
        error('swpipeline:RefinedICAFailed', 'ICA returned invalid unmixing weights.');
    end
    solution.icawinv = pinv(unmixing);
    clear training training_valid training_covariance;
    report.timing.ica_training = toc(stage_clock);
end

%% Score activations on broadband and identically filtered target-band data.

stage_clock = tic;
[slow, ~, coefficients] = pop_eegfiltnew(analysis, ...
    'locutoff', options.slow_band_hz(1), 'hicutoff', options.slow_band_hz(2));
guard = broad_guard + ceil((numel(coefficients) - 1) / 2);
valid = guarded_samples(segments, analysis.pnts, guard);
[broad_covariance, sample_count] = signal_covariance_chunked( ...
    analysis.data, valid, options.chunk_samples);
slow_covariance = signal_covariance_chunked(slow.data, valid, options.chunk_samples);
full_unmixing = zeros(size(unmixing, 1), analysis.nbchan);
full_unmixing(:, ica_indices) = unmixing;
broadband_r = correlations_from_covariance( ...
    broad_covariance, full_unmixing, derivation_matrix);
slow_r = correlations_from_covariance(slow_covariance, full_unmixing, derivation_matrix);
if options.reuse_ica
    % Catch another recording/reference even if labels and sample count match.
    verify_reused_ica_scores(cached_report.components, broadband_r, slow_r);
    clear cached_report;
end
selection = select_ocular_components(broadband_r, slow_r, options);
rejected_components = selection.rejected_components;
if numel(rejected_components) == size(unmixing, 1)
    error('swpipeline:AllComponentsSelected', ...
        'Every IC meets the ocular thresholds. Check derivations and correlation settings.');
end
windows = match_ocular_quiet_windows(events, segments, valid, analysis.srate, options);
report.components.broadband_r = broadband_r;
report.components.slow_r = slow_r;
report.components.broadband_windows = ...
    ocular_window_metrics(analysis.data, full_unmixing, windows);
report.components.slow_windows = ocular_window_metrics(slow.data, full_unmixing, windows);
variance_score = report.components.slow_windows.event_to_quiet_variance;
variance_score(~isfinite(variance_score)) = 0;
[~, ranked] = sortrows([-selection.correlation_score, -variance_score, ...
    (1:size(unmixing, 1))'], [1, 2, 3]);
selection.ranked_components = ranked;
report.selection = selection;
report.timing.component_scoring = toc(stage_clock);

%% Numeric target-band QC with fixed, pre-correction EOG references.

stage_clock = tic;
identity = eye(analysis.nbchan);
transform = identity;
if ~isempty(rejected_components)
    transform(ica_indices, ica_indices) = eye(numel(ica_indices)) - ...
        solution.icawinv(:, rejected_components) * unmixing(rejected_components, :);
end
before_operator = identity(ica_indices, :);
after_operator = transform(ica_indices, :);
report.qc.before = ocular_window_metrics(slow.data, before_operator, windows);
report.qc.after = ocular_window_metrics(slow.data, after_operator, windows);
report.qc.event_rms_ratio = safe_ratio( ...
    report.qc.after.event_rms, report.qc.before.event_rms);
report.qc.quiet_rms_ratio = safe_ratio( ...
    report.qc.after.quiet_rms, report.qc.before.quiet_rms);
report.qc.event_locked_rms_ratio = safe_ratio( ...
    report.qc.after.event_locked_rms, report.qc.before.event_locked_rms);
report.qc.slow_eog_r_before = correlations_from_covariance( ...
    slow_covariance, before_operator, derivation_matrix);
report.qc.slow_eog_r_after = correlations_from_covariance( ...
    slow_covariance, after_operator, derivation_matrix);
report.qc.channel_labels = {analysis.chanlocs(ica_indices).labels};
report.qc.matched_window_count = numel(windows.event_anchors);
if isempty(windows.event_anchors)
    warning('swpipeline:OcularQCUnavailable', ...
        ['No valid matched event/quiet windows; correlation selection still ran, ', ...
        'but event QC is NaN.']);
end
report.timing.target_band_qc = toc(stage_clock);

%% Apply only the selected projections to the original working EEG.

stage_clock = tic;
EEG = subtract_ocular_projection(EEG, solution, rejected_components, options.chunk_samples);
report.timing.component_subtraction = toc(stage_clock);
report.mode = 'refined';
report.options = options;
report.derivations = derivations;
report.input_channel_labels = {analysis.chanlocs.labels};
report.ica_channel_labels = {analysis.chanlocs(ica_indices).labels};
report.input_srate = EEG.srate;
report.assessment_srate = analysis.srate;
report.assessment_pnts = analysis.pnts;
report.effective_lowpass_hz = effective_lowpass;
report.notch_applied = notch_applied;
report.filter_guard_samples = guard;
report.correlation_sample_count = sample_count;
report.continuous_segments = segments;
report.training_rank = data_rank;
report.ica_solution = solution;
report.retained_original_components = setdiff(1:size(unmixing, 1), rejected_components);
report.events = events;
report.windows = windows;
report.timing.total = toc(total_clock);
if ~isfield(EEG, 'etc') || isempty(EEG.etc)
    EEG.etc = struct();
end
EEG.etc.refined_ocular = struct('rejected_original_components', rejected_components, ...
    'retained_original_components', report.retained_original_components, ...
    'training_highpass_hz', options.training_highpass_hz, ...
    'training_srate', analysis.srate, 'correlation_rule', options.correlation_rule, ...
    'ica_reused', report.ica_reused, 'ica_source_report', report.ica_source_report);
fprintf('Refined rule ''%s'': |r| >= %.2f broadband, >= %.2f target band.\n', ...
    options.correlation_rule, options.min_abs_corr_broadband, options.min_abs_corr_slow);
fprintf('Removed refined ocular components: %s (original trained IC indices).\n', ...
    mat2str(rejected_components));
fprintf('Target-band QC: %d matched windows; median event RMS ratio %.3f, quiet %.3f.\n', ...
    report.qc.matched_window_count, finite_median(report.qc.event_rms_ratio), ...
    finite_median(report.qc.quiet_rms_ratio));

end

function mask = guarded_samples(segments, pnts, guard)
mask = false(1, pnts);
for segment_idx = 1:size(segments, 1)
    first = segments(segment_idx, 1) + guard;
    last = segments(segment_idx, 2) - guard;
    if first <= last
        mask(first:last) = true;
    end
end
end

function EEG = clear_ica(EEG)
fields = {'icaweights', 'icasphere', 'icawinv', 'icachansind', 'icaact'};
for field_idx = 1:numel(fields)
    EEG.(fields{field_idx}) = [];
end
if isfield(EEG, 'icaquant')
    EEG = rmfield(EEG, 'icaquant');
end
if isfield(EEG, 'etc') && isfield(EEG.etc, 'ic_classification')
    EEG.etc = rmfield(EEG.etc, 'ic_classification');
end
if ~isfield(EEG, 'reject') || isempty(EEG.reject)
    EEG.reject = struct();
end
EEG.reject.gcompreject = [];
end

function ratio = safe_ratio(after, before)
ratio = after ./ before;
ratio(before <= 0 | ~isfinite(before)) = NaN;
end

function value = finite_median(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = median(values);
end
end

function validate_options(options)
validateattributes(options.reuse_ica, {'logical'}, {'scalar'});
if ~(ischar(options.ica_report_file) && isrow(options.ica_report_file)) && ...
        ~isempty(options.ica_report_file) && ...
        ~(isstring(options.ica_report_file) && isscalar(options.ica_report_file))
    error('swpipeline:InvalidICAReportPath', 'ica_report_file must be a file path.');
end
positive = {'training_srate', 'training_highpass_hz', 'eog_lowpass_hz', ...
    'mains_hz', 'notch_halfwidth_hz', 'event_window_sec', 'event_threshold_sd'};
for field_idx = 1:numel(positive)
    validateattributes(options.(positive{field_idx}), {'numeric'}, ...
        {'scalar', 'real', 'positive', 'finite'});
end
validateattributes(options.apply_mains_notch, {'logical'}, {'scalar'});
validateattributes(options.slow_band_hz, {'numeric'}, ...
    {'vector', 'numel', 2, 'positive', 'finite', 'real'});
validateattributes(options.peri_event_sec, {'numeric'}, ...
    {'vector', 'numel', 2, 'finite', 'real'});
if options.slow_band_hz(1) >= options.slow_band_hz(2) || ...
        options.peri_event_sec(1) >= options.peri_event_sec(2) || ...
        options.peri_event_sec(1) > 0 || options.peri_event_sec(2) < 0
    error('swpipeline:InvalidRefinedWindows', 'Filter and event-window edges are invalid.');
end
validateattributes(options.quiet_exclusion_sec, {'numeric'}, ...
    {'scalar', 'nonnegative', 'finite', 'real'});
validateattributes(options.max_qc_events, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'});
validateattributes(options.chunk_samples, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'});
validateattributes(options.rank_relative_tolerance, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>', 0, '<', 1});
validateattributes(options.random_seed, {'numeric'}, ...
    {'scalar', 'integer', 'nonnegative', 'finite', '<=', 2^32 - 1});
if ~any(strcmpi(options.ica_algorithm, {'runica', 'picard'}))
    error('swpipeline:InvalidICAAlgorithm', 'Select ICA algorithm ''runica'' or ''picard''.');
end
% Validate correlation settings before spending time training ICA.
select_ocular_components(zeros(1, 2), zeros(1, 2), options);
end

function [options, file] = refined_ica_options_for_dataset(config, dataset_id, index)
%REFINED_ICA_OPTIONS_FOR_DATASET Resolve one dataset's cache without silent refits.

file = fullfile(config.ica_cache_directory, [dataset_id, '_refined_ica.mat']);
if ~isempty(config.ica_report_files) && ~isempty(config.ica_report_files{index})
    file = config.ica_report_files{index};
end
options = config.refined;
options.ica_report_file = file;
switch config.refined_ica_mode
    case 'auto'
        options.reuse_ica = exist(file, 'file') == 2;
    case 'reuse'
        if exist(file, 'file') ~= 2
            error('swpipeline:MissingICAReport', 'ICA cache required: %s', file);
        end
        options.reuse_ica = true;
    case 'train'
        options.reuse_ica = false;
end
if options.reuse_ica
    loaded = load(file, 'report');
    if isfield(loaded, 'report') && isfield(loaded.report, 'dataset_id') && ...
            ~strcmp(loaded.report.dataset_id, dataset_id)
        error('swpipeline:ICACacheDataset', 'The ICA cache belongs to a different dataset ID.');
    end
end

end

function save_refined_ica_cache(report, file)
%SAVE_REFINED_ICA_CACHE Install the full pre-rejection report atomically.

directory = fileparts(file);
if isempty(directory)
    directory = pwd;
end
if exist(directory, 'dir') ~= 7
    mkdir(directory);
end
temporary = [tempname(directory), '.mat'];
cleanup = onCleanup(@() delete_if_present(temporary));
save(temporary, 'report', '-v7');
[ok, message] = movefile(temporary, file, 'f');
if ~ok
    error('swpipeline:ICACacheWrite', 'Cannot save ICA cache: %s', message);
end

end

function delete_if_present(file)
if exist(file, 'file') == 2
    delete(file);
end
end

function output_files = save_refined_ocular_report(report, output_directory)
%SAVE_REFINED_OCULAR_REPORT Persist signed correlations, selections, and band QC.
%   CSVs are readable without MATLAB. MAT includes event times, matched window
%   anchors, pre-rejection weights, waveforms, settings, and original IC indices.

if exist(output_directory, 'dir') ~= 7
    [created, message] = mkdir(output_directory);
    if ~created
        error('swpipeline:CannotCreateOcularReportDirectory', ...
            'Cannot create ocular-report directory %s: %s', output_directory, message);
    end
end

n_components = size(report.components.broadband_r, 1);
rank = zeros(n_components, 1);
rank(report.selection.ranked_components) = (1:n_components)';
component_scores = table((1:n_components)', rank, ...
    report.components.broadband_r(:, 1), report.components.broadband_r(:, 2), ...
    report.components.slow_r(:, 1), report.components.slow_r(:, 2), ...
    report.selection.correlation_score, ...
    report.components.broadband_windows.event_to_quiet_variance, ...
    report.components.slow_windows.event_to_quiet_variance, ...
    report.selection.matched_derivations(:, 1), ...
    report.selection.matched_derivations(:, 2), report.selection.selected, ...
    'VariableNames', {'OriginalIC', 'Rank', 'BroadbandR_VEOG', 'BroadbandR_HEOG', ...
    'SlowBandR_VEOG', 'SlowBandR_HEOG', 'CorrelationScore', ...
    'EventQuietVarianceRatio_Broadband', 'EventQuietVarianceRatio_SlowBand', ...
    'ThresholdMatch_VEOG', 'ThresholdMatch_HEOG', 'Removed'});
component_scores = component_scores(report.selection.ranked_components, :);

target_band_qc = table(report.qc.channel_labels(:), ...
    report.qc.before.event_rms, report.qc.after.event_rms, report.qc.event_rms_ratio, ...
    report.qc.before.quiet_rms, report.qc.after.quiet_rms, report.qc.quiet_rms_ratio, ...
    report.qc.before.event_locked_rms, report.qc.after.event_locked_rms, ...
    report.qc.event_locked_rms_ratio, ...
    report.qc.slow_eog_r_before(:, 1), report.qc.slow_eog_r_after(:, 1), ...
    report.qc.slow_eog_r_before(:, 2), report.qc.slow_eog_r_after(:, 2), ...
    'VariableNames', {'Channel', 'EventRMS_Before', 'EventRMS_After', 'EventRMS_Ratio', ...
    'QuietRMS_Before', 'QuietRMS_After', 'QuietRMS_Ratio', 'EventLockedRMS_Before', ...
    'EventLockedRMS_After', 'EventLockedRMS_Ratio', 'VEOG_R_Before', 'VEOG_R_After', ...
    'HEOG_R_Before', 'HEOG_R_After'});

output_files = {fullfile(output_directory, 'ocular_component_scores.csv'), ...
    fullfile(output_directory, 'ocular_target_band_qc.csv'), ...
    fullfile(output_directory, 'refined_ocular_report.mat')};
writetable(component_scores, output_files{1});
writetable(target_band_qc, output_files{2});
save(output_files{3}, 'report', '-v7');
fprintf('Refined ocular reports saved to:\n%s\n', output_directory);

end

function segments = continuous_sample_segments(EEG)
%CONTINUOUS_SAMPLE_SEGMENTS Inclusive intervals separated by EEGLAB boundaries.
%   A fractional boundary lies between samples; the next segment starts after
%   its floor. Boundary events at the recording edges create no empty interval.

starts = 1;
if isfield(EEG, 'event') && ~isempty(EEG.event)
    indices = eeg_findboundaries(EEG.event);
    latencies = [EEG.event(indices).latency];
    latencies = latencies(isfinite(latencies));
    starts = [starts, floor(latencies) + 1];
end
starts = unique(starts(starts >= 1 & starts <= EEG.pnts));
segments = [starts(:), [starts(2:end) - 1, EEG.pnts]'];

end

function correlations = correlations_from_covariance(covariance, targets, references)
%CORRELATIONS_FROM_COVARIANCE Pearson r for two linear signal derivations.
%   Gives Pearson r between rows of TARGETS*X and REFERENCES*X.
%   Constant signals return NaN, so they cannot trigger IC rejection.

cross_covariance = targets * covariance * references';
target_variance = sum((targets * covariance) .* targets, 2);
reference_variance = sum((references * covariance) .* references, 2);
denominator = sqrt(max(target_variance, 0) * max(reference_variance, 0)');
correlations = cross_covariance ./ denominator;
correlations(denominator <= 0 | ~isfinite(denominator)) = NaN;
finite = isfinite(correlations);
correlations(finite) = max(-1, min(1, correlations(finite)));

end

function events = detect_ocular_events(signals, srate, segments, window_sec, threshold)
%DETECT_OCULAR_EVENTS Preserve the supplied broad ocular-event detector.

validateattributes(window_sec, {'numeric'}, {'scalar', 'positive', 'finite'});
validateattributes(threshold, {'numeric'}, {'scalar', 'positive', 'finite'});
win = round(window_sec * srate);
if win < 2
    error('swpipeline:ShortEOGWindow', 'The EOG detector window must have two samples.');
end
events = repmat(struct('onsets', [], 'block_max_score', []), 1, size(signals, 1));
for signal_idx = 1:size(signals, 1)
    x = double(signals(signal_idx, :));
    onset_parts = cell(1, size(segments, 1));
    score_parts = cell(size(onset_parts));
    for segment_idx = 1:size(segments, 1)
        first = segments(segment_idx, 1);
        last = segments(segment_idx, 2);
        n_blocks = floor((last - first + 1) / win);
        if n_blocks < 2
            continue;
        end
        blocks = reshape(x(first:(first + n_blocks * win - 1)), win, n_blocks);
        block_ok = all(isfinite(blocks), 1);
        block_sd = std(blocks, 0, 1);
        candidates = find(block_ok(1:end-1) & block_ok(2:end) & ...
            block_sd(2:end) > block_sd(1:end-1)) + 1;
        onsets = zeros(1, numel(candidates));
        max_scores = nan(size(onsets));
        count = 0;
        for candidate_idx = 1:numel(candidates)
            bs = first + (candidates(candidate_idx) - 1) * win;
            be = bs + win - 1;
            y = x((bs - win):be);
            if ~all(isfinite(y))
                continue;
            end
            % Centering changes no local z-score and limits cancellation.
            y = y - mean(y);
            cs = [0, cumsum(y)];
            cs2 = [0, cumsum(y .^ 2)];
            starts = 1:win;
            sums = cs(starts + win) - cs(starts);
            sums2 = cs2(starts + win) - cs2(starts);
            local_mean = sums / win;
            variance = max(0, (sums2 - sums .^ 2 / win) / (win - 1));
            sd = sqrt(variance);
            scores = abs(y((win + 1):end) - local_mean) ./ sd;
            scores(~isfinite(scores) | sd <= 0) = NaN;
            crossing = find(scores >= threshold, 1, 'first');
            if ~isempty(crossing)
                count = count + 1;
                onsets(count) = bs + crossing - 1;
                max_scores(count) = max(scores(isfinite(scores)));
            end
        end
        onset_parts{segment_idx} = onsets(1:count);
        score_parts{segment_idx} = max_scores(1:count);
    end
    events(signal_idx).onsets = [onset_parts{:}];
    events(signal_idx).block_max_score = [score_parts{:}];
end

end

function [solution, cached] = load_refined_ica_report( ...
    report_file, analysis, derivations, ica_indices, options)
%LOAD_REFINED_ICA_REPORT Load the full pre-rejection fit for threshold reruns.
%   Channel order, selected data, derivations, and filtering must match.
%   Correlations are checked again after scoring, before any subtraction.

if isempty(report_file) || exist(report_file, 'file') ~= 2
    error('swpipeline:MissingICAReport', 'Prior refined MAT report not found: %s', report_file);
end
loaded = load(report_file, 'report');
if ~isfield(loaded, 'report') || ~isstruct(loaded.report) || ~isscalar(loaded.report)
    error('swpipeline:InvalidICAReport', 'The MAT file must contain a scalar report structure.');
end
cached = loaded.report;
required = {'mode', 'options', 'derivations', 'input_channel_labels', ...
    'ica_channel_labels', 'assessment_srate', 'assessment_pnts', ...
    'continuous_segments', 'training_rank', 'ica_solution', 'components'};
if ~all(isfield(cached, required)) || ~strcmp(cached.mode, 'refined')
    error('swpipeline:InvalidICAReport', 'Use a report from the refined ocular pipeline.');
end
if ~isequal(cached.input_channel_labels(:), {analysis.chanlocs.labels}') || ...
        ~isequal(cached.ica_channel_labels(:), {analysis.chanlocs(ica_indices).labels}')
    error('swpipeline:ICAReportChannels', ...
        'Saved ICA channel labels/order differ. Restore the original channel configuration.');
end
if cached.assessment_srate ~= analysis.srate || ...
        cached.assessment_pnts ~= analysis.pnts || ...
        ~isequal(double(cached.continuous_segments), continuous_sample_segments(analysis))
    error('swpipeline:ICAReportData', ...
        'Saved ICA recording selection/rate differ. Restore the original recording and assessment-rate settings.');
end
if ~isequaln(cached.derivations, derivations)
    error('swpipeline:ICAReportDerivations', ...
        'Restore the ocular derivations used in the saved run.');
end
% Thresholds, rule, event/QC settings, and chunk size may change without fitting.
fixed = {'training_srate', 'training_highpass_hz', 'eog_lowpass_hz', ...
    'apply_mains_notch', 'mains_hz', 'notch_halfwidth_hz', 'slow_band_hz', ...
    'ica_algorithm', 'random_seed', 'rank_relative_tolerance'};
for setting_idx = 1:numel(fixed)
    name = fixed{setting_idx};
    if ~isfield(cached.options, name) || ~isequaln(cached.options.(name), options.(name))
        error('swpipeline:ICAReportSettings', ...
            'Saved ICA setting %s differs. Restore it or disable reuse_ica to train again.', name);
    end
end

solution = cached.ica_solution;
if ~isstruct(solution) || ~isscalar(solution) || ...
        ~all(isfield(solution, {'icaweights', 'icasphere', 'icawinv', 'icachansind'}))
    error('swpipeline:InvalidICAReport', 'The report lacks the full original ICA solution.');
end
names = {'icaweights', 'icasphere', 'icawinv'};
for matrix_idx = 1:numel(names)
    validateattributes(solution.(names{matrix_idx}), {'single', 'double'}, ...
        {'2d', 'real', 'finite', 'nonempty'});
end
n_channels = numel(ica_indices);
n_components = size(solution.icaweights, 1);
if size(solution.icaweights, 2) ~= size(solution.icasphere, 1) || ...
        size(solution.icasphere, 2) ~= n_channels || n_components < 2 || ...
        n_components > n_channels || cached.training_rank ~= n_components || ...
        ~isequal(size(solution.icawinv), [n_channels, n_components]) || ...
        ~isequal(double(solution.icachansind(:)), double(ica_indices(:))) || ...
        ~all(isfield(cached.components, {'broadband_r', 'slow_r'})) || ...
        ~isequal(size(cached.components.broadband_r), [n_components, 2]) || ...
        ~isequal(size(cached.components.slow_r), [n_components, 2])
    error('swpipeline:InvalidICAReport', 'Saved full ICA dimensions/indices are inconsistent.');
end
unmixing = double(solution.icaweights) * double(solution.icasphere);
expected_mixing = pinv(unmixing);
relative_error = norm(double(solution.icawinv) - expected_mixing, 'fro') / ...
    max(1, norm(expected_mixing, 'fro'));
if any(~isfinite(unmixing(:))) || relative_error > 1e-6
    error('swpipeline:InvalidICAReport', 'Saved ICA mixing and unmixing matrices disagree.');
end

end

function windows = match_ocular_quiet_windows(events, segments, valid, srate, options)
%MATCH_OCULAR_QUIET_WINDOWS Pair event windows with nearby quiet windows.

offsets = round(options.peri_event_sec * srate);
width = offsets(2) - offsets(1) + 1;
onsets = unique([events.onsets]);
quiet = valid;
radius = ceil(max(options.quiet_exclusion_sec, ...
    max(abs(options.peri_event_sec))) * srate);
for onset_idx = 1:numel(onsets)
    first = max(1, onsets(onset_idx) - radius);
    last = min(numel(valid), onsets(onset_idx) + radius);
    quiet(first:last) = false;
end
windows.offsets = offsets;
windows.event_anchors = [];
windows.quiet_anchors = [];
windows.total_detections = numel(onsets);
windows.total_eligible_events = 0;
if isempty(onsets)
    return;
end

valid_counts = [0, cumsum(double(valid))];
quiet_counts = [0, cumsum(double(quiet))];
eligible = false(size(onsets));
event_segments = zeros(size(onsets));
quiet_anchors = [];
quiet_segments = [];
for segment_idx = 1:size(segments, 1)
    first = segments(segment_idx, 1);
    last = segments(segment_idx, 2);
    event_idx = find(onsets + offsets(1) >= first & onsets + offsets(2) <= last);
    starts = onsets(event_idx) + offsets(1);
    ends = onsets(event_idx) + offsets(2);
    eligible(event_idx) = valid_counts(ends + 1) - valid_counts(starts) == width;
    event_segments(event_idx) = segment_idx;
    starts = first:width:(last - width + 1);
    ends = starts + width - 1;
    is_quiet = quiet_counts(ends + 1) - quiet_counts(starts) == width;
    centers = starts(is_quiet) - offsets(1);
    quiet_anchors = [quiet_anchors, centers]; %#ok<AGROW>
    quiet_segments = [quiet_segments, repmat(segment_idx, size(centers))]; %#ok<AGROW>
end
eligible_idx = find(eligible);
windows.total_eligible_events = numel(eligible_idx);
if numel(eligible_idx) > options.max_qc_events
    subset = unique(round(linspace(1, numel(eligible_idx), options.max_qc_events)));
    eligible_idx = eligible_idx(subset);
end
available = true(size(quiet_anchors));
event_matches = zeros(1, numel(eligible_idx));
quiet_matches = zeros(size(event_matches));
count = 0;
for match_idx = 1:numel(eligible_idx)
    event_idx = eligible_idx(match_idx);
    possible = find(available & quiet_segments == event_segments(event_idx));
    if isempty(possible)
        continue;
    end
    [~, nearest] = min(abs(quiet_anchors(possible) - onsets(event_idx)));
    quiet_idx = possible(nearest);
    count = count + 1;
    event_matches(count) = onsets(event_idx);
    quiet_matches(count) = quiet_anchors(quiet_idx);
    available(quiet_idx) = false;
end
windows.event_anchors = event_matches(1:count);
windows.quiet_anchors = quiet_matches(1:count);

end

function matrix = ocular_derivation_matrix(chanlocs, derivations)
%OCULAR_DERIVATION_MATRIX Mean(positive group) minus mean(negative group).
%   MATRIX * DOUBLE(EEG.data) gives the configured ocular signals.

labels = {chanlocs.labels};
matrix = zeros(numel(derivations), numel(labels));
for derivation_idx = 1:numel(derivations)
    positive = derivations(derivation_idx).positive_labels;
    negative = derivations(derivation_idx).negative_labels;
    [found_positive, positive_idx] = ismember(positive, labels);
    [found_negative, negative_idx] = ismember(negative, labels);
    if isempty(positive) || isempty(negative) || ...
            ~all(found_positive) || ~all(found_negative)
        error('swpipeline:MissingEOGChannel', ...
            'Channels required for %s are missing.', derivations(derivation_idx).name);
    end
    matrix(derivation_idx, positive_idx) = 1 / numel(positive_idx);
    matrix(derivation_idx, negative_idx) = -1 / numel(negative_idx);
end

end

function metrics = ocular_window_metrics(data, operator, windows)
%OCULAR_WINDOW_METRICS Equal-duration event and matched quiet measurements.
%   OPERATOR creates component activations or projected scalp signals without
%   storing a full-duration activation matrix. Unavailable metrics are NaN.

offsets = windows.offsets(1):windows.offsets(2);
count = numel(windows.event_anchors);
n_signals = size(operator, 1);
metrics.mean_event_waveform = nan(n_signals, numel(offsets));
metrics.event_variance = nan(n_signals, 1);
metrics.quiet_variance = nan(n_signals, 1);
metrics.event_rms = nan(n_signals, 1);
metrics.quiet_rms = nan(n_signals, 1);
metrics.event_locked_rms = nan(n_signals, 1);
metrics.event_to_quiet_variance = nan(n_signals, 1);
if count == 0
    return;
end

event_sum = zeros(n_signals, numel(offsets));
event_variance = zeros(n_signals, 1);
quiet_variance = zeros(n_signals, 1);
event_energy = zeros(n_signals, 1);
quiet_energy = zeros(n_signals, 1);
for window_idx = 1:count
    event = operator * double(data(:, windows.event_anchors(window_idx) + offsets));
    quiet = operator * double(data(:, windows.quiet_anchors(window_idx) + offsets));
    event_sum = event_sum + event;
    event_variance = event_variance + var(event, 0, 2);
    quiet_variance = quiet_variance + var(quiet, 0, 2);
    event_energy = event_energy + sum(event .^ 2, 2);
    quiet_energy = quiet_energy + sum(quiet .^ 2, 2);
end
metrics.mean_event_waveform = event_sum / count;
metrics.event_variance = event_variance / count;
metrics.quiet_variance = quiet_variance / count;
metrics.event_rms = sqrt(event_energy / (count * numel(offsets)));
metrics.quiet_rms = sqrt(quiet_energy / (count * numel(offsets)));
metrics.event_locked_rms = sqrt(mean(metrics.mean_event_waveform .^ 2, 2));
metrics.event_to_quiet_variance = metrics.event_variance ./ metrics.quiet_variance;
metrics.event_to_quiet_variance(metrics.quiet_variance <= 0) = NaN;

end

function selection = select_ocular_components(broadband_r, slow_r, options)
%SELECT_OCULAR_COMPONENTS Automated, sign-independent IC-EOG threshold rule.
%   The default requires both cutoffs for the SAME derivation. 'either' is an
%   optional more permissive rule. No components are removed merely by rank.

if ~isequal(size(broadband_r), size(slow_r))
    error('swpipeline:CorrelationShapeMismatch', 'Both correlation arrays must match.');
end
validateattributes(options.min_abs_corr_broadband, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>', 0, '<=', 1});
validateattributes(options.min_abs_corr_slow, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>', 0, '<=', 1});
broad_pass = isfinite(broadband_r) & ...
    abs(broadband_r) >= options.min_abs_corr_broadband;
slow_pass = isfinite(slow_r) & abs(slow_r) >= options.min_abs_corr_slow;
switch lower(char(options.correlation_rule))
    case 'both'
        matches = broad_pass & slow_pass;
    case 'either'
        matches = broad_pass | slow_pass;
    otherwise
        error('swpipeline:InvalidCorrelationRule', 'Use correlation_rule ''both'' or ''either''.');
end
selection.matched_derivations = matches;
selection.selected = any(matches, 2);
selection.rejected_components = find(selection.selected)';
broad_score = abs(broadband_r) / options.min_abs_corr_broadband;
slow_score = abs(slow_r) / options.min_abs_corr_slow;
broad_score(~isfinite(broad_score)) = 0;
slow_score(~isfinite(slow_score)) = 0;
normalized = min(broad_score, slow_score);
if strcmpi(options.correlation_rule, 'either')
    normalized = max(broad_score, slow_score);
end
selection.correlation_score = max(normalized, [], 2);
[~, selection.ranked_components] = sort(selection.correlation_score, 'descend');

end

function [covariance, sample_count] = signal_covariance_chunked(data, mask, chunk_samples)
%SIGNAL_COVARIANCE_CHUNKED Stable covariance without an activation cache.
%   Accumulates centered blocks in double precision with the parallel variance
%   identity. Peak temporary storage scales with CHUNK_SAMPLES, not duration.

validateattributes(chunk_samples, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'});
if numel(mask) ~= size(data, 2)
    error('swpipeline:CovarianceMaskMismatch', 'The mask must match the sample count.');
end
sample_count = 0;
running_mean = zeros(size(data, 1), 1);
scatter = zeros(size(data, 1));
for first = 1:chunk_samples:size(data, 2)
    indices = first:min(first + chunk_samples - 1, size(data, 2));
    indices = indices(mask(indices));
    if isempty(indices)
        continue;
    end
    block = double(data(:, indices));
    if any(~isfinite(block(:)))
        error('swpipeline:NonfiniteICAData', ...
            'Refined ICA requires finite EEG in the selected samples.');
    end
    block_count = size(block, 2);
    block_mean = mean(block, 2);
    block = bsxfun(@minus, block, block_mean);
    combined_count = sample_count + block_count;
    delta = block_mean - running_mean;
    scatter = scatter + block * block' + ...
        (sample_count * block_count / combined_count) * (delta * delta');
    running_mean = running_mean + delta * (block_count / combined_count);
    sample_count = combined_count;
end
if sample_count < 2
    error('swpipeline:TooFewCorrelationSamples', ...
        'Too few samples remain after guarding filter edges and boundaries.');
end
covariance = (scatter + scatter') / (2 * (sample_count - 1));

end

function EEG = subtract_ocular_projection(EEG, solution, rejected, chunk_samples)
%SUBTRACT_OCULAR_PROJECTION Subtract only selected ICs from broadband EEG.

unmixing = double(solution.icaweights) * double(solution.icasphere);
mixing = double(solution.icawinv);
indices = solution.icachansind(:)';
if ~isempty(rejected)
    validateattributes(rejected, {'numeric'}, ...
        {'vector', 'integer', 'positive', 'finite', '<=', size(unmixing, 1)});
end
rejected = unique(rejected(:)');
keep = setdiff(1:size(unmixing, 1), rejected);
if isempty(keep)
    error('swpipeline:AllComponentsSelected', ...
        'Every IC meets the ocular thresholds. Check derivations and correlation settings.');
end
if ~isempty(rejected)
    rejected_unmixing = unmixing(rejected, :);
    rejected_mixing = mixing(:, rejected);
    for first = 1:chunk_samples:EEG.pnts
        samples = first:min(first + chunk_samples - 1, EEG.pnts);
        block = double(EEG.data(indices, samples));
        block = block - rejected_mixing * (rejected_unmixing * block);
        EEG.data(indices, samples) = cast(block, 'like', EEG.data);
    end
end

EEG.icaweights = solution.icaweights(keep, :);
EEG.icasphere = solution.icasphere;
EEG.icawinv = solution.icawinv(:, keep);
EEG.icachansind = indices;
EEG.icaact = [];
if isfield(EEG, 'icaquant')
    EEG = rmfield(EEG, 'icaquant');
end
if isfield(EEG, 'dipfit')
    EEG = rmfield(EEG, 'dipfit');
end
if isfield(EEG, 'etc') && isfield(EEG.etc, 'ic_classification')
    EEG.etc = rmfield(EEG.etc, 'ic_classification');
end
if ~isfield(EEG, 'reject') || isempty(EEG.reject)
    EEG.reject = struct();
end
EEG.reject.gcompreject = false(1, numel(keep));
EEG = eeg_checkset(EEG);
EEG.icaact = [];

end

function verify_reused_ica_scores(cached_components, broadband_r, slow_r)
%VERIFY_REUSED_ICA_SCORES Confirm the saved fit is being scored on matching data.
%   Accept roundoff from chunk sizes/precision, but reject different data or
%   references before subtraction. NaN locations must match as well.

saved = {cached_components.broadband_r, cached_components.slow_r};
current = {broadband_r, slow_r};
for band_idx = 1:2
    previous = double(saved{band_idx});
    next = double(current{band_idx});
    if ~isequal(size(previous), size(next)) || ...
            ~isequal(isfinite(previous), isfinite(next)) || ...
            any(isinf(previous(:))) || any(isinf(next(:)))
        error('swpipeline:ICAReportScores', 'Saved/current IC-EOG correlation arrays disagree.');
    end
    finite = isfinite(previous);
    if any(abs(previous(finite) - next(finite)) > 1e-6)
        error('swpipeline:ICAReportScores', ...
            ['Saved/current IC-EOG correlations differ. Use the original uncorrected ', ...
            'dataset, recording selection, reference, and filtering for a threshold rerun.']);
    end
end

end
