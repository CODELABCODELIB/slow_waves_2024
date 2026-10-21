NEW SLOW-WAVE PIPELINE (last updated: October 16, 2026)


SETUP AND BATCH INPUT

Add EEGLAB/FIRfilt to the MATLAB path, initialize EEGLAB, then run
run_sw_pipeline.m. The old method also requires ICA Blink Metrics.

Set these fields at the top of the driver:

    config.input_directory = '/data/participants';
    config.file_pattern = '*.set';
    config.dataset_files = {};

An empty dataset_files list processes matching files in the input folder.
Alternatively specify full paths:

    config.dataset_files = {'/data/P01.set', '/data/P02.set'};

Keep associated .fdt files available. Each file/session is a separate dataset.
IDs default to filenames without .set. For repeated filenames or unsuitable
names, specify unique IDs in the same order:

    config.dataset_ids = {'P01_S1', 'P01_S2'};

MAIN SETTINGS

    config.skip_existing_complete = true;
    config.ocular_method = 'refined';       % 'old' or 'refined'
    config.enable_speedup = true;
    config.speedup_working_srate = 256;
    config.refined.min_abs_corr_broadband = 0.50;
    config.refined.min_abs_corr_slow = 0.50;
    config.refined.event_threshold_sd = 5.0;
    config.refined_ica_mode = 'auto';

Only one ocular method runs. Speed mode applies antialias downsampling before
ocular correction; it never upsamples. Final SW analysis stays at 128 Hz.

Processing order:
    Load -> resolve EOG derivations -> remove technical channels -> optional
    early downsampling -> ocular correction -> remove E63/E64 and their
    interpolation-template entries -> interpolate scalp channels -> original
    SW preprocessing -> detection -> artifact limits/top 10% -> save results.

Reference electrodes remain E52/E58. Refined EOG definitions use channel labels:
    VEOG = mean(E35,E49) - mean(E63,E64)
    HEOG = E60 - E50
Change these definitions for a different montage. Missing required channels
fail the dataset rather than silently changing the derivations/reference.

REFINED ICA AND REUSE

Refined ICA is trained on a separate 2-Hz high-pass scalp-channel copy at up
to 256 Hz, with rank-aware PCA when necessary. Correlations are assessed on
broadband and matched 0.5-4 Hz data. Both absolute correlation thresholds must
be met for the SAME ocular derivation. Only the selected IC projections are
subtracted from the broadband working EEG; the training filters do not become
the SW input filters. The old method uses the ICA stored in the original .set
and follows the ICA Blink Metrics approach.

Each dataset's full refined decomposition and fit metadata are stored at:
    ICA_Cache/<dataset_id>_refined_ica.mat

Modes:
    'auto'  - reuse a cache if present; train and save if missing.
    'train' - explicitly train and replace that dataset's cache.
    'reuse' - require a compatible cache; never train automatically.

An incompatible existing cache fails that dataset rather than silently
retraining. Cached channels, recording/fit settings, and correlations are
checked. Changing correlation thresholds or event/QC settings permits reuse.
Use the original .set input, not a previously ocular-corrected version.

First batch:
    config.refined_ica_mode = 'train';
    config.ica_cache_directory = fullfile(pipeline_dir, 'ICA_Cache');

Later batch:
    config.refined_ica_mode = 'reuse';
    config.ica_cache_directory = fullfile(pipeline_dir, 'ICA_Cache');

Code and caches received separately:
    config.refined_ica_mode = 'reuse';
    config.ica_cache_directory = '/received/ICA_Cache';

Keep original cache filenames/dataset IDs. Full cache MAT files are needed,
including fit metadata; isolated weight matrices or CSV reports are not enough.
Earlier refined_ocular_report.mat files can instead be supplied explicitly:

    config.ica_report_files = {'/previous/P01/refined_ocular_report.mat', ...
                               '/previous/P02/refined_ocular_report.mat'};

One path per input dataset, in the same order. Empty entries use automatic
cache paths. Leave the entire list empty for normal automatic cache lookup.

SKIPPING COMPLETED DATASETS

config.skip_existing_complete=true (default) skips datasets only when required
outputs validate and match the input files and analysis settings. Successful
runs save processing_complete.mat. Datasets without this record, or with
incomplete or changed results, are processed again. File checks use sizes and
modification times, not content hashes. Set this option to false to force a
rerun, including after code changes or when requesting a new ICA fit; skipping
otherwise takes precedence over ICA mode, including 'train'.

OUTPUTS

    Outputs/<dataset_id>/<old-or-refined>/wave_results.mat
    Outputs/<dataset_id>/<old-or-refined>/processing_complete.mat
    Outputs/<dataset_id>/<old-or-refined>/Topoplots/
    Outputs/<dataset_id>/refined/Ocular_QC/

wave_results.mat contains results, top10_filtered_results, wave_pars, chanlocs
and processing_info. Refined QC includes component scores, target-band QC and
the full report. Event QC uses -50 to +200 ms windows and matched quiet windows
away from detected events. QC measures are diagnostics of correction effects.

The four original topoplots are saved and closed by default. Optional settings:
    config.save_topoplots = true;
    config.show_topoplots = false;
    config.save_preprocessed_EEG = false;

Exact detector-grid positions, negative-peak seconds, segment IDs and clock
maps are saved with the wave results. Boundary-separated segments are detected
independently. Legacy position fields remain available. Existing ICA caches
and wave-result formats remain compatible with the preceding final version.

batch_summary.csv records ok/failed/skipped status, timings, ICA reuse and
skip_reason. ICA reuse fields describe work performed in the current run;
skipped datasets do not load or reuse ICA. Failed datasets also save
processing_error.mat. continue_on_error=true proceeds to the next dataset;
false stops. Datasets that are processed again overwrite derived files in the
same dataset/method folder; choose a separate output directory to preserve runs.
Consult the latest batch summary because old outputs can remain after a failed
rerun. A stale error log does not override a later valid completion record.
Input .set/.fdt files are not overwritten.

CODE LAYOUT

run_sw_pipeline.m                  Driver, batch loop and EOG definitions
prepare_sw_batch.m                 Input list and essential batch checks
prepare_channels.m                 Channel/template removal and interpolation
eeg_timing.m                       Early resampling and source-clock metadata
refined_ocular_defaults.m          Refined-method defaults
dataset_completion.m               Completion records and output checks
remove_refined_ocular_artifacts.m  Refined correction, ICA cache and QC helpers
detect_sw_segments.m               Boundary-aware detector wrapper
preprocessing_complete.m           Original SW preprocessing
twalldetectnew_TA_v4.m             Original detector with timing fixes
meanfilt.m                         Original smoothing
filter_results.m                   Original wave selection
compute_wave_pars.m                Original parameter summaries
visualize_wave_pars.m              Original four topoplots

