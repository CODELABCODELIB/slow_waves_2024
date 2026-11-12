%% Supplementary Figure 4: coarse-grained relationship between SW features and smartphone interactions
% a) population-average Spearman rho (1-min bins) between the number of smartphone
%    interactions and SW density / amplitude, per electrode
% b) hierarchical mass-univariate regression (LIMO): level 1 per participant and
%    electrode rate ~ density + amplitude, level 2 one-sample t-test on the betas with
%    cluster correction (alpha 0.05, 1000 bootstraps); significant electrodes = black dots
%
% Workspace script, run from run_paper_figures.m. Needs:
%   res, EEG (EEG.chanlocs = analysed channels), figures_save_path, supp4_data_path,
%   neighbours_dir (expected_chanlocs.mat, channeighbstructmat.mat), LIMO + EEGLAB in path
% Optional: rebuild_cache (0 reuses the LIMO result for the same recordings)
%
% Outputs: <figures_save_path>/supp_fig4a.svg (plain rho), supp_fig4a_masked.svg (rho set
% to 0 where p >= 0.05 before averaging, as plot_playground.m), supp_fig4b.svg;
% data in <supp4_data_path>/{spearman.mat, regression.mat, recordings.txt, limo_*}
%
% Features are computed here instead of with prepare_features_rate: that function indexes
% all SW amplitudes of a channel with a mask over only the SWs in the tap period, which
% shifts the amplitudes when there are SWs before the first tap. Windowing is the same
% (1-min windows from the first tap; density/amplitude NaN in windows without SWs).
if ~exist('rebuild_cache','var'); rebuild_cache = 0; end
if ~exist(figures_save_path,'dir'); mkdir(figures_save_path); end
if ~exist(supp4_data_path,'dir'); mkdir(supp4_data_path); end
n_chans = numel(EEG.chanlocs);
n_pp = numel(res);
time_win = 60000; % ms
alpha_rho = 0.05;
% blue-white-red colormap
half = 128;
bwr = [linspace(0,1,half)', linspace(0,1,half)', ones(half,1); ...
    ones(half,1), linspace(1,0,half)', linspace(1,0,half)'];
%% features per participant: rate, density, amplitude (channels x windows)
features = cell(n_pp,1);
for pp=1:n_pp
    features{pp} = supp4_features(res(pp), n_chans, time_win);
end
%% a) Spearman correlations
rho = nan(n_pp,n_chans); p = nan(n_pp,n_chans);
rho_amp = nan(n_pp,n_chans); p_amp = nan(n_pp,n_chans);
for pp=1:n_pp
    f = features{pp};
    for chan=1:n_chans
        [rho(pp,chan),p(pp,chan)] = corr(f.rate(chan,:)', f.density(chan,:)', 'Type','Spearman', 'rows','complete');
        [rho_amp(pp,chan),p_amp(pp,chan)] = corr(f.rate(chan,:)', f.amplitude(chan,:)', 'Type','Spearman', 'rows','complete');
    end
end
save(fullfile(supp4_data_path,'spearman.mat'), 'rho','p','rho_amp','p_amp','time_win')
mean_rho = {trimmean(rho,20,1), trimmean(rho_amp,20,1)};
masked_rho = {trimmean(rho.*(p<alpha_rho),20,1), trimmean(rho_amp.*(p_amp<alpha_rho),20,1)};
fprintf('Supp Fig 4a plain rho: density [%.3f %.3f], amplitude [%.3f %.3f]\n', ...
    min(mean_rho{1}), max(mean_rho{1}), min(mean_rho{2}), max(mean_rho{2}));
lim_masked = max(abs([masked_rho{:}]));
if ~(lim_masked > 0); lim_masked = 0.2; end
fprintf('Supp Fig 4a masked rho: density [%.3f %.3f], amplitude [%.3f %.3f], colour limits +-%.3f\n', ...
    min(masked_rho{1}), max(masked_rho{1}), min(masked_rho{2}), max(masked_rho{2}), lim_masked);
supp4_topo_pair(mean_rho, {[],[]}, EEG.chanlocs, 0.2, bwr, {'\rho_{density}','\rho_{amplitude}'}, ...
    'Spearman''s rho', fullfile(figures_save_path,'supp_fig4a.svg'));
supp4_topo_pair(masked_rho, {[],[]}, EEG.chanlocs, lim_masked, bwr, {'\rho_{density}','\rho_{amplitude}'}, ...
    sprintf('Spearman''s rho (p<%.2f, else 0)',alpha_rho), fullfile(figures_save_path,'supp_fig4a_masked.svg'));
%% b) LIMO regression (cached per recording set)
regression_file = fullfile(supp4_data_path,'regression.mat');
recordings_file = fullfile(supp4_data_path,'recordings.txt');
cached = false;
if ~rebuild_cache && exist(regression_file,'file') && exist(recordings_file,'file')
    previous = strtrim(splitlines(fileread(recordings_file)));
    previous = previous(~cellfun('isempty',previous));
    cached = isequal(previous(:), {res.pp}');
end
beta_names = {'density','amplitude'};
if cached
    fprintf('Supp Fig 4b: using cached LIMO results in %s (rebuild_cache = 1 to rerun)\n', supp4_data_path)
    load(regression_file, 'betas','one_sample','mask','cluster_p')
else
    if exist(recordings_file,'file'); delete(recordings_file); end
    % level 1: rate ~ density + amplitude + intercept, per participant and electrode
    betas = nan(n_chans,1,3,n_pp); % electrodes x frames x [density amplitude intercept] x participants
    for pp=1:n_pp
        f = features{pp};
        for chan=1:n_chans
            X = [f.density(chan,:)', f.amplitude(chan,:)', ones(size(f.rate,2),1)];
            Y = f.rate(chan,:)';
            keep = ~any(isnan(X),2) & ~isnan(Y);
            if sum(keep) <= size(X,2); continue; end % too few windows for 3 parameters
            model = limo_glm(Y(keep), X(keep,:), 0, 0, 2, 'OLS', 'Time', 0, 1);
            betas(chan,1,:,pp) = model.betas(:);
        end
        fprintf('Supp Fig 4b level 1: %s done (%d/%d)\n', res(pp).pp, pp, n_pp);
    end
    % level 2: one-sample t-test per beta + cluster correction
    tmp = load(fullfile(neighbours_dir,'expected_chanlocs.mat'));
    expected_chanlocs = tmp.expected_chanlocs(:,1:n_chans);
    tmp = load(fullfile(neighbours_dir,'channeighbstructmat.mat'));
    channeighbstructmat = tmp.channeighbstructmat(1:n_chans,1:n_chans);
    one_sample = nan(n_chans,1,5,2);
    mask = zeros(n_chans,1,2);
    cluster_p = nan(n_chans,1,2);
    previous_dir_supp4 = pwd;
    restore_dir_supp4 = onCleanup(@() cd(previous_dir_supp4));
    for b=1:2
        limo_path = fullfile(supp4_data_path, sprintf('limo_%s',beta_names{b}));
        if ~exist(limo_path,'dir'); mkdir(limo_path); end
        cd(limo_path)
        LIMO = struct();
        LIMO.dir = limo_path;
        LIMO.Analysis = 'Time';
        LIMO.Level = 2;
        LIMO.data.chanlocs = expected_chanlocs;
        LIMO.data.neighbouring_matrix = channeighbstructmat;
        LIMO.data.data = limo_path;
        LIMO.data.data_dir = limo_path;
        LIMO.data.sampling_rate = 1000;
        LIMO.design.bootstrap = 1000;
        LIMO.design.tfce = 0;
        LIMO.design.name = 'one sample t-test';
        LIMO.design.electrode = [];
        LIMO.design.X = [];
        LIMO.design.method = 'Trimmed Mean';
        out = limo_random_robust(1, reshape(betas(:,1,b,:),[n_chans,1,n_pp]), b, LIMO);
        out = char(out);
        if isempty(out) || exist(out,'file') == 2; out = limo_path; end % some LIMO versions return a file
        tmp = load(fullfile(out, sprintf('one_sample_ttest_parameter_%d.mat',b)), 'one_sample');
        one_sample(:,:,:,b) = reshape(tmp.one_sample, [n_chans,1,5]);
        tmp = load(fullfile(out, 'H0', sprintf('H0_one_sample_ttest_parameter_%d.mat',b)), 'H0_one_sample');
        n_boot = size(tmp.H0_one_sample, ndims(tmp.H0_one_sample));
        H0 = reshape(tmp.H0_one_sample, [n_chans,1,2,n_boot]);
        [mask(:,:,b), cluster_p(:,:,b)] = limo_cluster_correction(one_sample(:,:,4,b).^2, one_sample(:,:,5,b), ...
            reshape(H0(:,:,1,:).^2,[n_chans,1,n_boot]), reshape(H0(:,:,2,:),[n_chans,1,n_boot]), ...
            channeighbstructmat, 2, 0.05);
    end
    clear restore_dir_supp4 % back to the previous folder
    save(regression_file, 'betas','one_sample','mask','cluster_p','beta_names')
    % written after the tests finished, so an interrupted run is not reused
    writecell({res.pp}', recordings_file)
end
t_vals = {one_sample(:,1,4,1)', one_sample(:,1,4,2)'};
sig = {find(mask(:,1,1) > 0)', find(mask(:,1,2) > 0)'};
for b=1:2
    fprintf('Supp Fig 4b beta %s: t [%.2f %.2f], %d significant electrodes: %s\n', beta_names{b}, ...
        min(t_vals{b}), max(t_vals{b}), numel(sig{b}), strjoin({EEG.chanlocs(sig{b}).labels}, ' '));
end
supp4_topo_pair(t_vals, sig, EEG.chanlocs, 7, bwr, {'\beta_{density}','\beta_{amplitude}'}, ...
    't-values (MCC, \alpha=0.05)', fullfile(figures_save_path,'supp_fig4b.svg'));

%% local functions
function f = supp4_features(r, n_chans, time_win)
% rate, density and median amplitude per channel in time_win windows from the first tap
starts = r.taps(1):time_win:floor((r.taps(end)-r.taps(1))/time_win)*time_win+r.taps(1);
n_win = numel(starts);
f.rate = nan(n_chans,n_win); f.density = nan(n_chans,n_win); f.amplitude = nan(n_chans,n_win);
taps = r.taps;
for chan=1:n_chans
    sw = [r.refilter.channels(chan).maxnegpk{:}];
    amp = abs([r.refilter.channels(chan).maxnegpkamp{:}] - [r.refilter.channels(chan).maxpospkamp{:}]);
    for w=1:n_win
        in_win = sw >= starts(w) & sw <= starts(w)+time_win;
        f.rate(chan,w) = sum(taps >= starts(w) & taps <= starts(w)+time_win);
        if any(in_win)
            f.density(chan,w) = sum(in_win);
            f.amplitude(chan,w) = median(amp(in_win));
        end
    end
end
end

function supp4_topo_pair(values, dots, chanlocs, lim, cmap, titles, cbar_label, save_file)
% two topoplots side by side with one colorbar; dots = channel indices drawn as black dots
h = figure('Position',[100 100 900 400]);
tiledlayout(1,2,'TileSpacing','compact');
for k=1:2
    nexttile;
    if isempty(dots{k})
        topoplot(values{k}, chanlocs, 'maplimits', [-lim lim], 'style', 'map', 'electrodes', 'off', 'colormap', cmap);
    else
        topoplot(values{k}, chanlocs, 'maplimits', [-lim lim], 'style', 'map', 'electrodes', 'off', ...
            'colormap', cmap, 'emarker2', {dots{k}, '.', 'k', 14, 1});
    end
    colormap(gca, cmap); clim([-lim lim]);
    title(titles{k}, 'FontSize', 16);
end
cb = colorbar; cb.Layout.Tile = 'east';
cb.Ticks = [-lim lim];
ylabel(cb, cbar_label);
saveas(h, save_file)
close(h)
end
