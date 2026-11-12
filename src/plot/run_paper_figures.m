%% Paper figures 1-3 from the refined-ICA rerun
% SW to behavior plots: <output_root>/figures/{pop,sw_to_behavior,rates} (same as run_paper_sw_plots.m)
% Fig 1: SW features movie vs phone, FieldTrip cluster-permutation paired t-tests
%        (local_sleep/manuscript_analyses/fig_1)
% Fig 2: per-participant NNMF of SW JIDs + k-means clustering of the meta-JIDs
% Fig 3: LIMO paired t-test of SW JIDs, phone - movie (src/GLM_JIDs)
%
% Run on the server (set the paths below first):
%   nohup matlab -batch "run('<repo>/src/plot/run_paper_figures.m')" > paper_figures.out 2>&1 &
% Only some figures, e.g.:
%   matlab -batch "do_fig2 = 0; do_fig3 = 0; run('<repo>/src/plot/run_paper_figures.m')"
% Also the individual-level (per participant) figures:
%   matlab -batch "do_individual_plots = 1; run('<repo>/src/plot/run_paper_figures.m')"
% Recompute everything instead of reusing earlier results:
%   matlab -batch "rebuild_cache = 1; run('<repo>/src/plot/run_paper_figures.m')"
% Quick test on 2 participants (outputs in <output_root>/test_run, real results untouched):
%   matlab -batch "test_mode = 1; run('<repo>/src/plot/run_paper_figures.m')" > test_run.out 2>&1
%
% Outputs: <output_root>/paper_figures/{fig1,fig2,fig3}, data in <output_root>/paper_data,
% log of each run in <output_root>/paper_figures/logs/run_paper_figures_<date_time>.log,
% participants/recordings/clusters per figure in <output_root>/paper_figures/subject_overview.csv.
%
% Reused between runs unless rebuild_cache = 1 (results for other recordings are never reused):
%   res                     <output_root>/plot_data/res_refined.mat (delete it to rebuild;
%                           not saved while some wave_results.mat are unreadable)
%   Fig 1 recording choice  <paper_data>/fig1/top10_SWs.mat
%   Fig 2 NNMF              <paper_data>/sw_jid_<condition>/ (always resumed)
%   Fig 2 K selection       <paper_figures>/fig2/k_selection_<condition>.mat
%   Fig 3 LIMO test         <paper_data>/GLM_movie_vs_behavior/
% A failing section does not stop the run: all errors are listed at the end (and in the log),
% after which the script errors so matlab -batch exits non-zero.
%% settings
if ~exist('output_root','var'); output_root = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sw_refined_ica_rerun'; end
if ~exist('do_sw_plots','var'); do_sw_plots = 1; end % pop / sw_to_behavior / rates (as run_paper_sw_plots.m)
if ~exist('do_fig1','var'); do_fig1 = 1; end
if ~exist('do_fig2','var'); do_fig2 = 1; end
if ~exist('do_fig3','var'); do_fig3 = 1; end
% 1: also the per-participant figures (sw_to_behavior_plots, Fig 1 participant topoplots,
% Fig 3 per-channel figures with a tile per participant); 0: population figures only
if ~exist('do_individual_plots','var'); do_individual_plots = 0; end
if ~exist('rebuild_cache','var'); rebuild_cache = 0; end % 1: recompute instead of reusing earlier results
if ~exist('test_mode','var'); test_mode = 0; end % 1: only n_test participants, outputs in <output_root>/test_run
if ~exist('n_test','var'); n_test = 2; end
% dependencies (TODO: fill in the paths marked with <...> for this server)
eeglab_dir = '/home/ruchella/imports';                 % EEGLAB (topoplot, pop_resample, eeg_emptyset)
tapdata_dir = '/home/ruchella/TapDataAnalysis';        % taps2JID
fieldtrip_dir = '/home/ruchella/imports/fieldtrip-20260924';        % Fig 1
nnmf_dir = '/home/ruchella/NNMF/nnmf_pipeline_spams';  % Fig 2 (nnmf_cv, choose_best_k, perform_nnmf, stable_nnmf + SPAMS)
limo_dir = '/home/ruchella/imports/limo_tools';                       % Fig 3
neighbours_dir = '/home/ruchella/slow_waves_2023_original/data'; % Fig 3
% channel locations of the original Fig 1 run (run_paired_t_test_pipeline.m loads chanlocs.mat):
% used for Fig 1 (neighbours, topoplots) and the Fig 2 topoplots. TODO: check this path
if ~exist('chanlocs_file','var'); chanlocs_file = '/home/ruchella/slow_waves_2023_original/data/chanlocs.mat'; end
% Fig 2 number of clusters (check paper_figures/fig2/k_selection_*.svg, then rerun with do_fig1=0, do_fig3=0)
% NB the original paper figures (plot_playground.m) used 3 movie and 4 phone clusters
if ~exist('K_movie','var'); K_movie = 2; end
if ~exist('K_phone','var'); K_phone = 4; end
%% paths
repo_src = fileparts(fileparts(mfilename('fullpath')));
repo_root = fileparts(repo_src);
% inputs are always read from output_root, outputs of a test run go to <output_root>/test_run
if test_mode; out_root = sprintf('%s/test_run',output_root); else; out_root = output_root; end
figures_root = sprintf('%s/paper_figures',out_root);
paper_data = sprintf('%s/paper_data',out_root);
needed = {eeglab_dir, tapdata_dir};
if do_fig1; needed{end+1} = fieldtrip_dir; end
if do_fig2; needed{end+1} = nnmf_dir; end
if do_fig3; needed = [needed, {limo_dir, neighbours_dir}]; end
missing = needed(~cellfun(@(d) exist(d,'dir')==7, needed));
if (do_fig1 || do_fig2) && ~exist(chanlocs_file,'file'); missing{end+1} = chanlocs_file; end
if ~isempty(missing)
    error('run_paper_figures:MissingPath', 'Set these paths at the top of %s:\n  %s', ...
        mfilename('fullpath'), strjoin(missing, '\n  '));
end
if do_fig3 && (~exist(fullfile(neighbours_dir,'expected_chanlocs.mat'),'file') || ...
        ~exist(fullfile(neighbours_dir,'channeighbstructmat.mat'),'file'))
    error('run_paper_figures:MissingNeighbours', 'expected_chanlocs.mat / channeighbstructmat.mat not in %s', neighbours_dir);
end
addpath(genpath(repo_src))
% fieldtrip/limo live inside imports: add them only where needed (FieldTrip must not be genpath'd)
imports_path = strsplit(genpath(eeglab_dir), pathsep);
imports_path = imports_path(~startsWith(imports_path, {fieldtrip_dir, limo_dir}));
addpath(strjoin(imports_path, pathsep))
addpath(genpath(tapdata_dir))
addpath(fullfile(repo_root,'local_sleep','manuscript_analyses','fig_1'))
for folder = {figures_root, paper_data, sprintf('%s/logs',figures_root)}
    if ~exist(folder{1}, 'dir'); mkdir(folder{1}); end
end
% everything printed from here on is also written to the log
log_file = sprintf('%s/logs/run_paper_figures_%s.log', figures_root, datestr(now,'yyyymmdd_HHMMSS'));
diary(log_file)
fprintf('Log: %s\n', log_file)
if test_mode; fprintf('TEST MODE: %d participants, outputs in %s\n', n_test, out_root); end
fprintf('do_individual_plots = %d, rebuild_cache = %d\n', do_individual_plots, rebuild_cache);
if ~license('test','Statistics_Toolbox')
    fprintf(2, 'Statistics and Machine Learning Toolbox not available: quantile, trimmean, kmeans, evalclusters will fail\n');
end
set(0, 'DefaultFigureVisible', 'off');
rng(2026) % NNMF and k-means are randomly initialised
run_errors = {}; % {section, MException} of every failed section
previous_dir = pwd;
% subject overview, filled per section and written at the end (also when a section fails)
overview_res = struct('participant',{},'dataset_id',{},'source_file',{},'res_index',{});
overview_fig1 = struct('participant',{},'fig1_dataset_id',{},'fig1_eeg_file',{},'movie_min',{},'phone_min',{});
overview_fig2 = struct(); % .<condition>.n_components / .labels per res index
%% res for the selected recordings (Fig 2 and 3), same as run_paper_sw_plots.m
res_ok = true;
try
    if test_mode && ~exist(sprintf('%s/plot_data/res_refined.mat',output_root),'file')
        % no cache: stop after the first recordings with aligned taps
        % (2x: participant_selection keeps one recording per participant)
        [res, EEG, participant_ids, source_files] = build_refined_res(output_root, 'max_datasets', 2*n_test, ...
            'plot_data_path', sprintf('%s/plot_data',out_root));
    else
        [res, EEG, participant_ids, source_files] = build_refined_res(output_root);
    end
    if test_mode
        n_keep = min(n_test,numel(res));
        res = res(1:n_keep); participant_ids = participant_ids(1:n_keep); source_files = source_files(1:n_keep);
        fprintf('TEST MODE: using %s\n', strjoin({res.pp}, ' '))
    end
    fprintf('%d recordings (one per participant) used for the SW plots, Fig 2 and Fig 3\n', numel(res));
    chanlocs62 = EEG.chanlocs;
    for pp=1:numel(res)
        overview_res(pp) = struct('participant', participant_ids{pp}, 'dataset_id', res(pp).pp, ...
            'source_file', source_files{pp}, 'res_index', pp);
    end
catch ME
    res_ok = false;
    run_errors(end+1,:) = {'res', ME};
    fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf(2, 'res could not be built: skipping all figures\n');
end
%% channel locations of the original Fig 1 run (chanlocs.mat, 64 channels)
if res_ok && (do_fig1 || do_fig2)
    try
        tmp = load(chanlocs_file, 'chanlocs');
        chanlocs64 = tmp.chanlocs;
        % the data rows are the refined chanlocs: they must be the first 62 of chanlocs.mat
        if numel(chanlocs64) < numel(chanlocs62) || ...
                ~isequal({chanlocs64(1:numel(chanlocs62)).labels}, {chanlocs62.labels})
            error('run_paper_figures:ChanlocsMismatch', ['%s (%s) does not start with the analysed ' ...
                'channels (%s)'], chanlocs_file, strjoin({chanlocs64.labels},' '), strjoin({chanlocs62.labels},' '));
        end
        ocular_channels = numel(chanlocs62)+1:numel(chanlocs64); % E63/E64, as in run_paired_t_test_pipeline.m
    catch ME
        run_errors(end+1,:) = {'chanlocs.mat', ME};
        fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
        fprintf(2, 'chanlocs.mat could not be used: skipping Fig 1 and Fig 2\n');
        do_fig1 = 0; do_fig2 = 0;
    end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% SW to behavior plots (pop, rates, ...) %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_sw_plots && res_ok
    try
        figures_save_path = sprintf('%s/figures',out_root);
        data_save_path = out_root; % prepare_sw_data_for_plotting saves in <data_save_path>/plot_data
        save_string = ''; % no extra subfolder in sw_to_behavior_plots
        for folder = {sprintf('%s/pop',figures_save_path), sprintf('%s/sw_to_behavior',figures_save_path), ...
                sprintf('%s/rates',figures_save_path), sprintf('%s/plot_data',data_save_path)}
            if ~exist(folder{1}, 'dir'); mkdir(folder{1}); end
        end
        % population figures (pop/), incl. the electrode grid electrodes(_labelled).svg
        prepare_sw_data_for_plotting
        if do_individual_plots
            sw_to_behavior_plots % per participant (sw_to_behavior/, rates/)
        else
            fprintf('Individual SW to behavior plots skipped (do_individual_plots = 0)\n')
        end
        fprintf('SW to behavior plots done, figures in %s\n', figures_save_path)
    catch ME
        run_errors(end+1,:) = {'SW to behavior plots', ME};
        fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    end
    close all
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_fig1 && res_ok
    try
        addpath(fieldtrip_dir); ft_defaults;
        fig1_path = sprintf('%s/fig1',figures_root);
        fig1_data = sprintf('%s/fig1',paper_data);
        if ~exist(fig1_path,'dir'); mkdir(fig1_path); end
        % neighbours used by condition_contrast_v2 (distance 0.55 in chanlocs.mat units)
        incl_chanlocs = chanlocs64(setdiff(1:numel(chanlocs64), ocular_channels));
        xyz = [[incl_chanlocs.X]',[incl_chanlocs.Y]',[incl_chanlocs.Z]'];
        % pairwise Euclidean distances without pdist (no Statistics Toolbox needed)
        dist = sqrt(sum((permute(xyz,[1 3 2]) - permute(xyz,[3 1 2])).^2, 3));
        n_neighbours = sum(dist < 0.55, 2) - 1;
        fprintf('Fig 1 neighbours per channel (distance < 0.55): min %d, median %d, max %d\n', ...
            min(n_neighbours), median(n_neighbours), max(n_neighbours));
        % recording selection of the paper: longest phone period per participant, movie < 80 min, phone >= 15 min
        top10_file = sprintf('%s/top10_SWs.mat',fig1_data);
        if ~rebuild_cache && exist(top10_file,'file')
            fprintf('Fig 1: using cached %s (rebuild_cache = 1 to rebuild)\n', top10_file)
        else
            if test_mode; max_participants = n_test; else; max_participants = Inf; end
            build_top10_SWs_refined(output_root, fig1_data, 'max_participants', max_participants);
        end
        tmp = load(top10_file, 'top10_SWs');
        fig1_pids = fieldnames(tmp.top10_SWs);
        for i=1:numel(fig1_pids)
            p = tmp.top10_SWs.(fig1_pids{i});
            overview_fig1(i) = struct('participant', fig1_pids{i}, 'fig1_dataset_id', p.checkpoint_filename, ...
                'fig1_eeg_file', fullfile(p.eeg_filepath, p.eeg_filename), ...
                'movie_min', (p.movie_end - p.movie_start)/60000, 'phone_min', p.phone_length/60000);
        end
        fprintf('Fig 1: %d participants\n', numel(fig1_pids));
        cd(fig1_path) % topoplots are saved under pwd
        sw_pars = sw_pars_per_participant_v3(fig1_data, true, chanlocs64, ...
            'target_path', fig1_data, 'exclude_channels', ocular_channels, 'interpolate_outliers', false, ...
            'visualize', logical(do_individual_plots));
        save(sprintf('%s/sw_pars.mat',fig1_data), 'sw_pars', '-v7.3');
        aggregated_sw_pars = aggregate_sw_pars_v2(sw_pars, @mean, chanlocs64, 'exclude_channels', ocular_channels);
        save(sprintf('%s/aggregated_sw_pars.mat',fig1_data), 'aggregated_sw_pars', '-v7.3');
        [t_vals, sign_ch] = condition_contrast_v2(sw_pars, chanlocs64, 'exclude_channels', ocular_channels);
        t_test_results.t_vals = t_vals; t_test_results.sign_ch = sign_ch;
        save(sprintf('%s/t_test_results.mat',fig1_data), 't_test_results', '-v7.3');
        fprintf('Fig 1 done: %d participants, figures in %s\n', numel(fieldnames(sw_pars)), fig1_path)
    catch ME
        run_errors(end+1,:) = {'Fig 1', ME};
        fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    end
    cd(previous_dir)
    close all
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_fig2 && res_ok
    try
        addpath(genpath(nnmf_dir))
        fig2_path = sprintf('%s/fig2',figures_root);
        if ~exist(fig2_path,'dir'); mkdir(fig2_path); end
        conditions = {'phone','movie'};
        parameters = {'sw_jid','sw_jid_movie'};
        for i=1:numel(conditions)
            nnmf_path = sprintf('%s/sw_jid_%s',paper_data,conditions{i});
            if ~exist(nnmf_path,'dir'); mkdir(nnmf_path); end
            % NNMF results are numbered by position in res: only resume with the same recordings
            recordings_file = sprintf('%s/recordings.txt',nnmf_path);
            if exist(recordings_file,'file')
                previous = strtrim(splitlines(fileread(recordings_file)));
                previous = previous(~cellfun('isempty',previous));
                if ~isequal(previous(:), {res.pp}')
                    error('run_paper_figures:NNMFRecordings', ['%s was made for other recordings; ' ...
                        'delete that folder to rerun the NNMF'], nnmf_path);
                end
            else
                writecell({res.pp}', recordings_file)
            end
            fprintf('Fig 2 NNMF %s (%d participants)\n', conditions{i}, numel(res))
            sw_jid_nnmf_main(res,'save_path',nnmf_path,'parameter',parameters{i},'skip_existing',1) % always resumed (delete the folder to rerun)
        end
        % collect meta-JIDs and meta-locations (main_slow_waves.m 'prepare data for clustering')
        all_jids = struct(); all_maps = struct();
        for i=1:numel(conditions)
            jids = {}; maps = {};
            for pp=1:length(res)
                tmp = load(sprintf('%s/sw_jid_%s/reconstruct_%d',paper_data,conditions{i},pp));
                jids{pp} = tmp.reconstruct_all_chans; %#ok<SAGROW>
                tmp = load(sprintf('%s/sw_jid_%s/stable_basis_%d',paper_data,conditions{i},pp));
                maps{pp} = tmp.stable_basis_all_chans; %#ok<SAGROW>
            end
            all_jids.(conditions{i}) = cat(2,jids{:});
            all_maps.(conditions{i}) = cat(2,maps{:});
            % number of meta-JIDs (NNMF components) per participant, in res order
            overview_fig2.(conditions{i}).n_components = cellfun(@(x) size(x,2), jids);
        end
        % number of clusters: elbow (k-means error) and silhouette for K=1..10
        for i=1:numel(conditions)
            jids = all_jids.(conditions{i});
            jids(isnan(jids)) = 0;
            max_k = 10;
            % a test run can have fewer meta-JIDs than clusters
            if test_mode; max_k = max(1, min(max_k, size(jids,2)-1)); end
            k_file = sprintf('%s/k_selection_%s.mat',fig2_path,conditions{i});
            recordings = {res.pp};
            k_cached = false;
            if ~rebuild_cache && exist(k_file,'file')
                k_saved = load(k_file);
                k_cached = isequal(k_saved.recordings, recordings) && k_saved.max_k == max_k;
            end
            if k_cached
                fprintf('Fig 2: using cached K selection %s\n', k_file)
                kmeans_error = k_saved.kmeans_error; evaluation = k_saved.evaluation;
            else
                kmeans_error = zeros(1,max_k);
                for n_clus=1:max_k
                    [~,~,~,~,kmeans_error(n_clus)] = cluster(jids', 'modkmeans', 0, 'n_clus',n_clus, 'numreps',100);
                end
                evaluation = evalclusters(jids',"kmeans","silhouette","KList",1:max_k);
                save(k_file, 'kmeans_error', 'evaluation', 'recordings', 'max_k')
            end
            h = figure;
            tiledlayout(1,2)
            nexttile; plot(1:max_k,kmeans_error,'-o'); xlabel('K'); title(sprintf('k-means error %s',conditions{i}))
            nexttile; plot(evaluation); title(sprintf('silhouette %s',conditions{i}))
            saveas(h, sprintf('%s/k_selection_%s.svg',fig2_path,conditions{i}))
            close(h)
        end
        if test_mode
            K_movie = max(1, min(K_movie, size(all_jids.movie,2)-1));
            K_phone = max(1, min(K_phone, size(all_jids.phone,2)-1));
        end
        [~, overview_fig2.movie.labels] = plot_nnmf_clusters(all_jids.movie, all_maps.movie, chanlocs64(1:numel(chanlocs62)), ...
            'n_clus', K_movie, 'condition', 'movie', 'save_path', fig2_path);
        [~, overview_fig2.phone.labels] = plot_nnmf_clusters(all_jids.phone, all_maps.phone, chanlocs64(1:numel(chanlocs62)), ...
            'n_clus', K_phone, 'condition', 'phone', 'save_path', fig2_path);
        fprintf('Fig 2 done (K movie %d, K phone %d; %d movie and %d phone meta-JIDs of %d participants), figures in %s\n', ...
            K_movie, K_phone, size(all_jids.movie,2), size(all_jids.phone,2), numel(res), fig2_path)
    catch ME
        run_errors(end+1,:) = {'Fig 2', ME};
        fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    end
    close all
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_fig3 && res_ok
    try
        addpath(genpath(limo_dir))
        figures_save_path = sprintf('%s/fig3',figures_root);
        limo_save_path = sprintf('%s/GLM_movie_vs_behavior',paper_data);
        prepare_limo_level_2_data % uses do_individual_plots and rebuild_cache
        fprintf('Fig 3 done (%d participants), figures in %s/movie_vs_phone\n', numel(res), figures_save_path)
    catch ME
        run_errors(end+1,:) = {'Fig 3', ME};
        fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    end
    close all
end
%% subject overview: which participant/recording/file is in which figure
try
    overview_file = sprintf('%s/subject_overview.csv',figures_root);
    write_subject_overview(overview_file, overview_res, overview_fig1, overview_fig2, ...
        struct('sw_plots', do_sw_plots, 'fig2', do_fig2, 'fig3', do_fig3));
    fprintf('Subject overview: %s\n', overview_file)
catch ME
    run_errors(end+1,:) = {'subject overview', ME};
    fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
end
%% summary of the failed sections
cd(previous_dir)
if isempty(run_errors)
    fprintf('\nAll sections finished without errors\n')
    diary off
else
    fprintf(2, '\n%d section(s) failed:\n', size(run_errors,1));
    for i=1:size(run_errors,1)
        ME = run_errors{i,2};
        where = '';
        if ~isempty(ME.stack); where = sprintf(' (%s line %d)', ME.stack(1).name, ME.stack(1).line); end
        fprintf(2, '  %s: %s%s\n', run_errors{i,1}, ME.message, where);
    end
    diary off
    error('run_paper_figures:Failed', '%d section(s) failed, see %s', size(run_errors,1), log_file);
end

function write_subject_overview(overview_file, overview_res, overview_fig1, overview_fig2, sections)
% One row per participant (union of the res recordings and the Fig 1 selection).
% res_index = number of the participant in the per-participant files/figures
% (stable_basis_<n>.mat, *_pp_<n>.svg). Fig 1 selects its own recording per participant.
% clusters_<condition> = population cluster of each NNMF meta-JID of the participant.
res_names = cellfun(@matlab.lang.makeValidName, {overview_res.participant}, 'UniformOutput', false);
fig1_names = {overview_fig1.participant};
participants = unique([res_names, fig1_names], 'stable');
n = numel(participants);
col = @(v) repmat({v}, n, 1);
T = table(participants(:), col(''), col(''), col(''), nan(n,1), false(n,1), false(n,1), false(n,1), ...
    false(n,1), col(''), col(''), nan(n,1), nan(n,1), ...
    'VariableNames', {'participant','dataset_id','source_file','participant_folder','res_index', ...
    'in_sw_plots','in_fig2','in_fig3','in_fig1','fig1_dataset_id','fig1_eeg_file','fig1_movie_min','fig1_phone_min'});
conditions = fieldnames(overview_fig2);
for c=1:numel(conditions)
    T.(sprintf('n_nnmf_components_%s',conditions{c})) = nan(n,1);
    T.(sprintf('clusters_%s',conditions{c})) = col('');
    T.(sprintf('cluster_counts_%s',conditions{c})) = col('');
end
for i=1:numel(overview_res)
    r = find(strcmp(participants, res_names{i}));
    T.dataset_id{r} = overview_res(i).dataset_id;
    T.source_file{r} = overview_res(i).source_file;
    T.participant_folder{r} = overview_res(i).participant;
    T.res_index(r) = overview_res(i).res_index;
    T.in_sw_plots(r) = logical(sections.sw_plots);
    T.in_fig2(r) = logical(sections.fig2);
    T.in_fig3(r) = logical(sections.fig3);
end
for i=1:numel(overview_fig1)
    r = find(strcmp(participants, fig1_names{i}));
    T.in_fig1(r) = true;
    T.fig1_dataset_id{r} = overview_fig1(i).fig1_dataset_id;
    T.fig1_eeg_file{r} = overview_fig1(i).fig1_eeg_file;
    T.fig1_movie_min(r) = overview_fig1(i).movie_min;
    T.fig1_phone_min(r) = overview_fig1(i).phone_min;
end
% NNMF components and cluster labels per participant (labels are in res order)
for c=1:numel(conditions)
    info = overview_fig2.(conditions{c});
    if ~isfield(info, 'n_components'); continue; end
    has_labels = isfield(info, 'labels') && numel(info.labels) == sum(info.n_components);
    stop = cumsum(info.n_components);
    for i=1:numel(info.n_components)
        r = find(T.res_index == i);
        if numel(r) ~= 1
            fprintf(2, 'subject overview: no single row for res_index %d (%s), NNMF info skipped\n', i, conditions{c});
            continue
        end
        T.(sprintf('n_nnmf_components_%s',conditions{c}))(r) = info.n_components(i);
        if has_labels
            labels = info.labels(stop(i)-info.n_components(i)+1:stop(i));
            T.(sprintf('clusters_%s',conditions{c})){r} = strjoin(arrayfun(@num2str, labels(:)', 'UniformOutput', false), ';');
            [u,~,j] = unique(labels(:));
            T.(sprintf('cluster_counts_%s',conditions{c})){r} = strjoin(arrayfun(@(k,m) sprintf('%d:%d',k,m), ...
                u', accumarray(j,1)', 'UniformOutput', false), ';');
        end
    end
end
T = sortrows(T, 'res_index'); % NaN (Fig 1 only) last
writetable(T, overview_file);
end
