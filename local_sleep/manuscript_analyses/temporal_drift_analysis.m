function out = temporal_drift_analysis(top10_SWs, chanlocs, options)
% Linear model predicting binned SW count from condition, within-condition time, and their interaction (optional).
%   If include_interaction:
%       SW ~ 1 + cond + serial_wc + cond:serial_wc
%       Tests/plots: beta_cond, beta_serial_wc (movie slope), beta_interaction, beta_phone_slope (movie+interaction)
%   Else (reduced model):
%       SW ~ 1 + cond + serial_wc
%       Tests/plots: beta_cond, beta_common_slope (shared slope across conditions)
%
% Predictors
%   cond       : movie=0, phone=1 (length = nbins_movie + nbins_phone)
%   serial_wc  : serial number centered within each condition, then concatenated
%
% Usage:
%   out = temporal_drift_analysis(top10_SWs, EEG.chanlocs);
%   out = temporal_drift_analysis(top10_SWs, EEG.chanlocs, ...
%           struct('include_interaction',true,'regression','poisson','visualize',true));
%
% Inputs
%   top10_SWs : struct with participants as fields; channels in .top10_filtered_results.channels
%   chanlocs  : EEGLAB chanlocs with fields .labels, .X, .Y, .Z
%   options   : struct (defaults shown)
%       .fs_hz             = 1000
%       .bin_dur_s         = 60
%       .exclude_channels  = [63 64]
%       .neighbourdist     = 0.55
%       .minnbchan         = 2
%       .num_randomization = 1000
%       .clusteralpha      = 0.05
%       .alpha             = 0.05
%       .visualize         = false
%       .regression        = 'ols'      % 'ols' or 'poisson'
%       .include_interaction = true     % include cond×serial_wc term and phone-slope test
%
% Output (key fields)
%   out.participants(ip).movie/phone: edges, serial, sw_counts, nbins
%   out.participants(ip).fused: serial_fused, serial_wc_fused, cond_fused, sw_counts_fused, betas.*
%   out.group.beta_cond / beta_serial_wc / beta_interaction / beta_phone_slope / beta_common_slope (as applicable)
%   out.stats.cond / .serial_wc / .interaction / .phone_slope / .common_slope (as applicable)
%   out.included_channels, out.labels, out.regression_model, out.include_interaction

    arguments
        top10_SWs struct
        chanlocs  struct
        options.fs_hz             double = 1000
        options.bin_dur_s         double = 60
        options.exclude_channels  double = [63 64]
        options.neighbourdist     double = 0.55
        options.minnbchan         double = 2
        options.num_randomization double = 1000
        options.clusteralpha      double = 0.05
        options.alpha             double = 0.05
        options.visualize         logical = false
        options.regression (1,:) char {mustBeMember(options.regression,{'ols','poisson'})} = 'ols'
        options.include_interaction logical = true
    end

    fs = options.fs_hz;
    bin_len = round(options.bin_dur_s * fs);
    use_poisson = strcmpi(options.regression, 'poisson');
    include_interaction = options.include_interaction;

    participant_ids = fieldnames(top10_SWs);
    n_participants = numel(participant_ids);

    % Channels: included indices and labels/positions
    n_channels = numel(chanlocs);
    incl_channels = setdiff(1:n_channels, options.exclude_channels);
    n_incl = numel(incl_channels);

    labels = {chanlocs(incl_channels).labels};
    elec = [];
    elec.label = labels;
    elec.pnt   = [[chanlocs(incl_channels).X]', [chanlocs(incl_channels).Y]', [chanlocs(incl_channels).Z]'];

    % Preallocate per-participant containers
    participants(n_participants) = struct();

    % Group matrices
    beta_cond_all        = nan(n_participants, n_incl);
    beta_serial_wc_all   = nan(n_participants, n_incl);
    if include_interaction
        beta_interact_all    = nan(n_participants, n_incl);
        beta_phone_slope_all = nan(n_participants, n_incl);  % derived: movie + interaction
    else
        beta_common_slope_all = nan(n_participants, n_incl);
    end

    % --------------------------
    % Per-participant processing
    % --------------------------
    for ip = 1:n_participants
        pid = participant_ids{ip};
        P = top10_SWs.(pid);

        % Extract condition windows (in samples)
        movie_start = P.movie_start; movie_end = P.movie_end;
        phone_start = P.phone_start; phone_end = P.phone_end;

        if isfield(P, 'top10_filtered_results') && isfield(P.top10_filtered_results, 'channels')
            chans = P.top10_filtered_results.channels;
        else
            error('Participant %s lacks .top10_filtered_results.channels', pid);
        end

        % Compute bin edges (no partial bins) per condition
        [edges_movie, nbins_movie] = make_edges(movie_start, movie_end, bin_len);
        [edges_phone, nbins_phone] = make_edges(phone_start, phone_end, bin_len);

        serial_movie = (1:nbins_movie).';
        serial_phone = (1:nbins_phone).';

        % Per-electrode counts
        sw_counts_movie = nan(n_incl, nbins_movie);
        sw_counts_phone = nan(n_incl, nbins_phone);

        if nbins_movie >= 1
            for ic = 1:n_incl
                ch_idx = incl_channels(ic);
                negzx = get_times_safe(chans(ch_idx), 'negzx', edges_movie);
                sw_counts_movie(ic, :) = histcounts(negzx, edges_movie);
            end
        end

        if nbins_phone >= 1
            for ic = 1:n_incl
                ch_idx = incl_channels(ic);
                negzx = get_times_safe(chans(ch_idx), 'negzx', edges_phone);
                sw_counts_phone(ic, :) = histcounts(negzx, edges_phone);
            end
        end

        % Concatenate bins: movie first, then phone
        nbins_all = nbins_movie + nbins_phone;
        serial_fused = (1:nbins_all).';

        cond_fused = [zeros(nbins_movie,1); ones(nbins_phone,1)];          % movie=0, phone=1

        % Within-condition centered serial
        serial_movie_wc = serial_movie - mean(serial_movie);
        serial_phone_wc = serial_phone - mean(serial_phone);
        serial_wc_fused = [serial_movie_wc; serial_phone_wc];

        % Interaction (if included)
        if include_interaction
            interact_fused = cond_fused .* serial_wc_fused;
        end

        % Fused counts (chan × bins)
        sw_counts_fused = [sw_counts_movie, sw_counts_phone];

        % Regressions
        beta0_all   = nan(n_incl,1);
        b_cond      = nan(n_incl,1);
        b_serial    = nan(n_incl,1);   % movie slope if interaction is included; common slope otherwise
        b_interact  = nan(n_incl,1);   % only if include_interaction
        b_phone     = nan(n_incl,1);   % derived phone slope (movie + interaction) if include_interaction

        % Need both conditions present to estimate condition effect; need >=2 total bins to estimate slope
        can_fit = (nbins_movie >= 1) && (nbins_phone >= 1) && (nbins_all >= 2);

        if can_fit
            if include_interaction
                if use_poisson
                    X = [cond_fused, serial_wc_fused, interact_fused]; % glmfit adds intercept
                else
                    X = [ones(nbins_all,1), cond_fused, serial_wc_fused, interact_fused];
                end
            else
                if use_poisson
                    X = [cond_fused, serial_wc_fused]; % glmfit adds intercept
                else
                    X = [ones(nbins_all,1), cond_fused, serial_wc_fused];
                end
            end

            for ic = 1:n_incl
                y = sw_counts_fused(ic, :).';

                if use_poisson
                    if all(y==0)
                        beta0_all(ic) = NaN; b_cond(ic) = NaN; b_serial(ic) = NaN;
                        if include_interaction, b_interact(ic) = NaN; b_phone(ic) = NaN; end
                    else
                        try
                            b = glmfit(X, y, 'poisson', 'link','log');
                            beta0_all(ic) = b(1);
                            b_cond(ic)    = b(2);
                            b_serial(ic)  = b(3);
                            if include_interaction
                                b_interact(ic) = b(4);
                                b_phone(ic)    = b(3) + b(4);  % phone slope = movie + interaction
                            end
                        catch ME
                            warning('GLM failed (%s) ch %d: %s', pid, incl_channels(ic), ME.message);
                            beta0_all(ic) = NaN; b_cond(ic) = NaN; b_serial(ic) = NaN;
                            if include_interaction, b_interact(ic) = NaN; b_phone(ic) = NaN; end
                        end
                    end
                else
                    % OLS
                    b = X \ y;
                    beta0_all(ic) = b(1);
                    b_cond(ic)    = b(2);
                    b_serial(ic)  = b(3);
                    if include_interaction
                        b_interact(ic) = b(4);
                        b_phone(ic)    = b(3) + b(4);
                    end
                end
            end
        end

        % Store participant-level results
        participants(ip).id = pid;

        participants(ip).movie.edges_samples = edges_movie;
        participants(ip).movie.serial_nums   = serial_movie;
        participants(ip).movie.sw_counts     = sw_counts_movie;
        participants(ip).movie.nbins         = nbins_movie;

        participants(ip).phone.edges_samples = edges_phone;
        participants(ip).phone.serial_nums   = serial_phone;
        participants(ip).phone.sw_counts     = sw_counts_phone;
        participants(ip).phone.nbins         = nbins_phone;

        participants(ip).fused.serial_fused     = serial_fused;
        participants(ip).fused.serial_wc_fused  = serial_wc_fused;
        participants(ip).fused.cond_fused       = cond_fused;
        participants(ip).fused.sw_counts_fused  = sw_counts_fused;

        participants(ip).fused.betas.intercept  = beta0_all;
        participants(ip).fused.betas.cond       = b_cond;
        if include_interaction
            participants(ip).fused.betas.movie_slope     = b_serial;    % β_serial_wc
            participants(ip).fused.betas.interaction     = b_interact;  % β_interaction
            participants(ip).fused.betas.phone_slope     = b_phone;     % movie + interaction
        else
            participants(ip).fused.betas.common_slope    = b_serial;    % shared slope
        end

        % Add to group matrices
        beta_cond_all(ip, :)      = b_cond.';
        if include_interaction
            beta_serial_wc_all(ip, :) = b_serial.';
            beta_interact_all(ip, :)  = b_interact.';
            beta_phone_slope_all(ip,:) = b_phone.';
        else
            beta_common_slope_all(ip,:) = b_serial.';
        end
    end

    % ---------------------------------
    % Group-level FieldTrip statistics
    % ---------------------------------
    neighbours = build_neighbours(elec, options.neighbourdist);
    stats = struct();

    % Per-parameter subject filtering (strict: drop subjects with any NaN channel for that beta)
    valid_cond      = all(isfinite(beta_cond_all), 2);
    out.group.beta_cond = beta_cond_all(valid_cond, :);
    if ~isempty(out.group.beta_cond)
        stats.cond = run_cluster_onesample(out.group.beta_cond, elec, neighbours, ...
            options.minnbchan, options.clusteralpha, options.alpha, options.num_randomization);
    else
        stats.cond = [];
        warning('No valid participants for β_{cond}.');
    end

    if include_interaction
        valid_serial = all(isfinite(beta_serial_wc_all), 2);
        valid_inter  = all(isfinite(beta_interact_all), 2);
        % movie slope
        out.group.beta_serial_wc = beta_serial_wc_all(valid_serial, :);
        if ~isempty(out.group.beta_serial_wc)
            stats.serial_wc = run_cluster_onesample(out.group.beta_serial_wc, elec, neighbours, ...
                options.minnbchan, options.clusteralpha, options.alpha, options.num_randomization);
        else
            stats.serial_wc = [];
            warning('No valid participants for β_{serial\\_wc}.');
        end
        % interaction
        out.group.beta_interaction = beta_interact_all(valid_inter, :);
        if ~isempty(out.group.beta_interaction)
            stats.interaction = run_cluster_onesample(out.group.beta_interaction, elec, neighbours, ...
                options.minnbchan, options.clusteralpha, options.alpha, options.num_randomization);
        else
            stats.interaction = [];
            warning('No valid participants for β_{interaction}.');
        end
        % phone slope (derived): need both movie slope & interaction
        valid_phone = valid_serial & valid_inter;
        out.group.beta_phone_slope = beta_phone_slope_all(valid_phone, :);
        if ~isempty(out.group.beta_phone_slope)
            stats.phone_slope = run_cluster_onesample(out.group.beta_phone_slope, elec, neighbours, ...
                options.minnbchan, options.clusteralpha, options.alpha, options.num_randomization);
        else
            stats.phone_slope = [];
            warning('No valid participants for phone slope (β_{serial\\_wc}+β_{interaction}).');
        end
    else
        % Reduced model: common slope only
        valid_common = all(isfinite(beta_common_slope_all), 2);
        out.group.beta_common_slope = beta_common_slope_all(valid_common, :);
        if ~isempty(out.group.beta_common_slope)
            stats.common_slope = run_cluster_onesample(out.group.beta_common_slope, elec, neighbours, ...
                options.minnbchan, options.clusteralpha, options.alpha, options.num_randomization);
        else
            stats.common_slope = [];
            warning('No valid participants for common slope.');
        end
    end

    % Package outputs
    out.participants        = participants;
    out.included_channels   = incl_channels;
    out.labels              = labels;
    out.stats               = stats;
    out.regression_model    = options.regression;
    out.include_interaction = include_interaction;

    % ----------------
    % Visualization
    % ----------------
    if options.visualize
        if ~isempty(stats.cond)
            clim = max(abs(out.stats.cond.t_vals));
            topoplot_linreg(stats.cond.t_vals, chanlocs(incl_channels), clim, ...
                out.stats.cond.significant_channels, ...
                'Full Model: \beta_{cond} (phone vs movie) ~ 0', ...
                fullfile(pwd, 'topoplot_beta_cond.svg'));
        end
        if include_interaction
            if ~isempty(stats.serial_wc)
                clim = max(abs(out.stats.serial_wc.t_vals));
                topoplot_linreg(stats.serial_wc.t_vals, chanlocs(incl_channels), clim, ...
                    out.stats.serial_wc.significant_channels, ...
                    'Full Model: \beta_{serial\_wc} (movie slope) ~ 0', ...
                    fullfile(pwd, 'topoplot_beta_movie_slope.svg'));
            end
            if ~isempty(stats.interaction)
                clim = max(abs(out.stats.interaction.t_vals));
                topoplot_linreg(stats.interaction.t_vals, chanlocs(incl_channels), clim, ...
                    out.stats.interaction.significant_channels, ...
                    'Full Model: \beta_{interaction} (slope difference) ~ 0', ...
                    fullfile(pwd, 'topoplot_beta_interaction.svg'));
            end
            if ~isempty(stats.phone_slope)
                clim = max(abs(out.stats.phone_slope.t_vals));
                topoplot_linreg(stats.phone_slope.t_vals, chanlocs(incl_channels), clim, ...
                    out.stats.phone_slope.significant_channels, ...
                    'Full Model: \beta_{movie}+\beta_{interaction} (phone slope) ~ 0', ...
                    fullfile(pwd, 'topoplot_beta_phone_slope.svg'));
            end
        else
            if ~isempty(stats.common_slope)
                clim = max(abs(out.stats.common_slope.t_vals));
                topoplot_linreg(stats.common_slope.t_vals, chanlocs(incl_channels), clim, ...
                    out.stats.common_slope.significant_channels, ...
                    'Reduced Model: \beta_{common\_slope} ~ 0', ...
                    fullfile(pwd, 'topoplot_beta_common_slope.svg'));
            end
        end
    end
end

% --------- Helpers ---------

function [edges, nbins] = make_edges(start_samp, end_samp, bin_len)
    dur = end_samp - start_samp;
    nbins = floor(dur / bin_len);
    if nbins <= 0
        edges = start_samp + [0 0];
        nbins = 0;
        return;
    end
    edges = start_samp + (0:nbins)*bin_len; % half-open bins: [e(i), e(i+1))
end

function times = get_times_safe(ch_struct, fieldname, edges)
    % Return finite event times within [edges(1), edges(end)), accepting numeric or cell arrays.
    times = zeros(0,1);
    if ~isfield(ch_struct, fieldname) || isempty(ch_struct.(fieldname))
        return;
    end
    raw = ch_struct.(fieldname);
    if iscell(raw)
        raw = raw(~cellfun('isempty', raw));
        if isempty(raw), return; end
        raw = cellfun(@(v) v(:), raw, 'UniformOutput', false);
        times = vertcat(raw{:});
    else
        times = raw(:);
    end
    times = double(times(:));
    times = times(isfinite(times) & times >= edges(1) & times < edges(end));
end

function neighbours = build_neighbours(elec, neighbourdist)
    % Ensure FieldTrip available
    if exist('ft_defaults','file'), ft_defaults; end
    if ~exist('ft_prepare_neighbours','file')
        error('FieldTrip not found. Add FieldTrip to path (ft_defaults) before running.');
    end
    cfgn = [];
    cfgn.method = 'distance';
    cfgn.elec = elec;
    cfgn.neighbourdist = neighbourdist;
    neighbours = ft_prepare_neighbours(cfgn);
end

function out = run_cluster_onesample(beta_mat, elec, neighbours, minnbchan, clusteralpha, alpha, numrand)
    % beta_mat: subjects × channels
    nsub  = size(beta_mat, 1);
    nchan = size(beta_mat, 2);

    % Build FT timelock struct per subject (single time point)
    D = repmat(struct('label',[],'time',[],'dimord','','avg',[]), 1, nsub);
    for s = 1:nsub
        D(s).label  = elec.label(:);
        D(s).time   = 1;                 % single dummy time point
        D(s).dimord = 'chan_time';
        D(s).avg    = reshape(beta_mat(s,:).', [nchan 1]);  % chan × 1
    end

    % Zero condition
    D0 = D;
    for s = 1:nsub
        D0(s).avg = zeros(nchan, 1);
    end

    % Cluster config (paired test: real vs zero)
    cfg                  = [];
    cfg.method           = 'montecarlo';
    cfg.statistic        = 'depsamplesT';   % one-sample as paired (real vs zero)
    cfg.parameter        = 'avg';
    cfg.correctm         = 'cluster';
    cfg.clusterstatistic = 'maxsum';
    cfg.clusteralpha     = clusteralpha;
    cfg.alpha            = alpha;
    cfg.correcttail      = 'alpha';         % split alpha across tails
    cfg.tail             = 0;               % two-sided
    cfg.clustertail      = 0;
    cfg.minnbchan        = minnbchan;
    cfg.numrandomization = numrand;
    cfg.elec             = elec;
    cfg.neighbours       = neighbours;

    % Design: subjects × 2 conditions (real=1, zero=2)
    cfg.design = [1:nsub,       1:nsub;
                  ones(1,nsub), 2*ones(1,nsub)];
    cfg.uvar   = 1;   % subjects
    cfg.ivar   = 2;   % condition

    % Run stats
    D_cell  = num2cell(D);
    D0_cell = num2cell(D0);
    stat = ft_timelockstatistics(cfg, D_cell{:}, D0_cell{:});

    % Extract t-map (single time point) and significant channels
    tmap = stat.stat(:,1).';     % 1 × nchan

    sig = false(1, nchan);
    if isfield(stat, 'posclusters') && ~isempty(stat.posclusters)
        for c = 1:numel(stat.posclusters)
            if stat.posclusters(c).prob < alpha
                sig = sig | (stat.posclusterslabelmat(:,1) == c).';
            end
        end
    end
    if isfield(stat, 'negclusters') && ~isempty(stat.negclusters)
        for c = 1:numel(stat.negclusters)
            if stat.negclusters(c).prob < alpha
                sig = sig | (stat.negclusterslabelmat(:,1) == c).';
            end
        end
    end

    out = struct('stat', stat, 't_vals', tmap, 'significant_channels', find(sig));
end

function [] = topoplot_linreg(t_vals, chanlocs, color_limit, highlight_channels, plot_title, output_path)

    arguments
        t_vals              double
        chanlocs            struct
        color_limit         double
        highlight_channels  double = []
        plot_title          char = []
        output_path         char = pwd;
    end

    clf;
    cb_label   = 't-value';

    % draw head
    if ~isempty(highlight_channels)
        topoplot(t_vals, chanlocs, ...
            'emarker',  {'.', [0.5 0.5 0.5], 5}, ...
            'emarker2', {highlight_channels, '.', 'k', 15}, ...
            'style', 'both', 'shading', 'interp', 'plotrad', 0.85, 'headrad', 0.84);
    else
        topoplot(t_vals, chanlocs, ...
            'emarker',  {'.', [0.5 0.5 0.5], 5}, ...
            'style', 'both', 'shading', 'interp', 'plotrad', 0.85, 'headrad', 0.84);
    end

    % custom blue-white-red colormap
    n = 256;
    b = [0 0 1]; w = [1 1 1]; r = [1 0 0];
    newmap = zeros(n,3);
    for ii = 1:floor(n/2)
        newmap(ii,:) = b + (w-b)*(ii-1)/(floor(n/2)-1);
    end
    for ii = floor(n/2)+1:n
        newmap(ii,:) = w + (r-w)*(ii-floor(n/2)-1)/(n-floor(n/2)-1);
    end
    colormap(newmap);

    clim([-color_limit, color_limit]);

    title(plot_title,'FontSize',18);
    cb = colorbar;
    cb.FontSize      = 12;
    cb.Label.String  = cb_label;
    cb.Label.FontSize= 14;
    cb.Label.Rotation= 270;

    % white face, black rim
    patch = findobj(gcf,'Type','patch');
    set(patch,'FaceColor','white','EdgeColor','black','EdgeAlpha',0);
    lines = findobj(gcf,'Type','line');

    if ~isempty(highlight_channels)
        set(lines(3:5),'LineWidth',1.5);
        set(lines(6),'LineWidth',3);
    else
        set(lines(2:4),'LineWidth',1.5);
        set(lines(5),'LineWidth',3);
    end

    % save
    print(gcf,'-dsvg',output_path);
end