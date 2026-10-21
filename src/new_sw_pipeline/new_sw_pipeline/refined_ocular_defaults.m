function options = refined_ocular_defaults
%REFINED_OCULAR_DEFAULTS Settings for the documented ocular-correction route.
%   Numeric derivation inputs refer to the original loaded channel order.
%   Cell arrays of channel labels can be used instead for another montage.

options.veog_positive = [35, 49];
options.veog_negative = [63, 64];
options.heog_positive = 60;
options.heog_negative = 50;
options.training_srate = 256;
options.training_highpass_hz = 2;
options.eog_lowpass_hz = 100;
options.apply_mains_notch = true;
options.mains_hz = 50;
options.notch_halfwidth_hz = 1;
options.slow_band_hz = [0.5, 4];
options.min_abs_corr_broadband = 0.50;
options.min_abs_corr_slow = 0.50;
options.correlation_rule = 'both';  % Same EOG must meet both cutoffs.
options.event_window_sec = 0.200;
options.event_threshold_sd = 5.0;
options.peri_event_sec = [-0.050, 0.200];
options.quiet_exclusion_sec = 0.5;
options.max_qc_events = 1000;  % Evenly spaced detections; no random selection.
options.chunk_samples = 65536;
options.rank_relative_tolerance = 1e-10;
options.ica_algorithm = 'runica';  % 'picard' requires the EEGLAB Picard plugin.
options.random_seed = 1;
options.reuse_ica = false;       % true loads the full ICA from a prior report.
options.ica_report_file = '';    % Required when reuse_ica is true.

end
