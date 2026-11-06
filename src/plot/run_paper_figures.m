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
% Quick test on 2 participants (outputs in <output_root>/test_run, real results untouched):
%   matlab -batch "test_mode = 1; run('<repo>/src/plot/run_paper_figures.m')" > test_run.out 2>&1
%
% Outputs: <output_root>/paper_figures/{fig1,fig2,fig3}, data in <output_root>/paper_data,
% log of each run in <output_root>/paper_figures/logs/run_paper_figures_<date_time>.log.
% res is shared with run_paper_sw_plots.m (cached in <output_root>/plot_data/res_refined.mat).
% A failing section does not stop the run: all errors are listed at the end (and in the log),
% after which the script errors so matlab -batch exits non-zero.
%% settings
if ~exist('output_root','var'); output_root = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sw_refined_ica_rerun'; end
if ~exist('do_sw_plots','var'); do_sw_plots = 1; end % pop / sw_to_behavior / rates (as run_paper_sw_plots.m)
if ~exist('do_fig1','var'); do_fig1 = 1; end
if ~exist('do_fig2','var'); do_fig2 = 1; end
if ~exist('do_fig3','var'); do_fig3 = 1; end
if ~exist('test_mode','var'); test_mode = 0; end % 1: only n_test participants, outputs in <output_root>/test_run
if ~exist('n_test','var'); n_test = 2; end
% dependencies (TODO: fill in the paths marked with <...> for this server)
eeglab_dir = '/home/ruchella/imports';                 % EEGLAB (topoplot, pop_resample, eeg_emptyset)
tapdata_dir = '/home/ruchella/TapDataAnalysis';        % taps2JID
fieldtrip_dir = '/home/ruchella/imports/fieldtrip-20260924';        % Fig 1
nnmf_dir = '/home/ruchella/NNMF/nnmf_pipeline_spams';  % Fig 2 (nnmf_cv, choose_best_k, perform_nnmf, stable_nnmf + SPAMS)
limo_dir = '/home/ruchella/imports/limo_tools';                       % Fig 3
neighbours_dir = '/home/ruchella/slow_waves_2023_original/data'; % Fig 3
% Fig 2 number of clusters (check paper_figures/fig2/k_selection_*.svg, then rerun with do_fig1=0, do_fig3=0)
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
if ~license('test','Statistics_Toolbox')
    fprintf(2, 'Statistics and Machine Learning Toolbox not available: quantile, trimmean, kmeans, evalclusters will fail\n');
end
set(0, 'DefaultFigureVisible', 'off');
rng(2026) % NNMF and k-means are randomly initialised
run_errors = {}; % {section, MException} of every failed section
previous_dir = pwd;
%% res for the selected recordings (Fig 2 and 3), same as run_paper_sw_plots.m
res_ok = true;
try
    if test_mode && ~exist(sprintf('%s/plot_data/res_refined.mat',output_root),'file')
        % no cache: stop after the first recordings with aligned taps
        % (2x: participant_selection keeps one recording per participant)
        [res, EEG] = build_refined_res(output_root, 'max_datasets', 2*n_test, ...
            'plot_data_path', sprintf('%s/plot_data',out_root));
    else
        [res, EEG] = build_refined_res(output_root);
    end
    if test_mode
        res = res(1:min(n_test,numel(res)));
        fprintf('TEST MODE: using %s\n', strjoin({res.pp}, ' '))
    end
    chanlocs62 = EEG.chanlocs;
catch ME
    res_ok = false;
    run_errors(end+1,:) = {'res', ME};
    fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf(2, 'res could not be built: skipping all figures\n');
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
        prepare_sw_data_for_plotting
        sw_to_behavior_plots
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
        % neighbours used by condition_contrast_v2 (distance 0.55 in chanlocs units)
        xyz = [[chanlocs62.X]',[chanlocs62.Y]',[chanlocs62.Z]'];
        % pairwise Euclidean distances without pdist (no Statistics Toolbox needed)
        dist = sqrt(sum((permute(xyz,[1 3 2]) - permute(xyz,[3 1 2])).^2, 3));
        n_neighbours = sum(dist < 0.55, 2) - 1;
        fprintf('Fig 1 neighbours per channel (distance < 0.55): min %d, median %d, max %d\n', ...
            min(n_neighbours), median(n_neighbours), max(n_neighbours));
        if median(n_neighbours) < 2
            warning('Almost no neighbours at 0.55: chanlocs units differ from the old chanlocs.mat; clusters will not form.');
        end
        % recording selection of the paper: longest phone period per participant, movie < 80 min, phone >= 15 min
        if test_mode; max_participants = n_test; else; max_participants = Inf; end
        build_top10_SWs_refined(output_root, fig1_data, 'max_participants', max_participants);
        cd(fig1_path) % topoplots are saved under pwd
        sw_pars = sw_pars_per_participant_v3(fig1_data, true, chanlocs62, ...
            'target_path', fig1_data, 'exclude_channels', [], 'interpolate_outliers', false);
        save(sprintf('%s/sw_pars.mat',fig1_data), 'sw_pars', '-v7.3');
        aggregated_sw_pars = aggregate_sw_pars_v2(sw_pars, @mean, chanlocs62, 'exclude_channels', []);
        save(sprintf('%s/aggregated_sw_pars.mat',fig1_data), 'aggregated_sw_pars', '-v7.3');
        [t_vals, sign_ch] = condition_contrast_v2(sw_pars, chanlocs62, 'exclude_channels', []);
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
            sw_jid_nnmf_main(res,'save_path',nnmf_path,'parameter',parameters{i},'skip_existing',1)
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
        end
        % number of clusters: elbow (k-means error) and silhouette for K=1..10
        for i=1:numel(conditions)
            jids = all_jids.(conditions{i});
            jids(isnan(jids)) = 0;
            max_k = 10;
            % a test run can have fewer meta-JIDs than clusters
            if test_mode; max_k = max(1, min(max_k, size(jids,2)-1)); end
            kmeans_error = zeros(1,max_k);
            for n_clus=1:max_k
                [~,~,~,~,kmeans_error(n_clus)] = cluster(jids', 'modkmeans', 0, 'n_clus',n_clus, 'numreps',100);
            end
            evaluation = evalclusters(jids',"kmeans","silhouette","KList",1:max_k);
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
        plot_nnmf_clusters(all_jids.movie, all_maps.movie, chanlocs62, 'n_clus', K_movie, 'condition', 'movie', 'save_path', fig2_path);
        plot_nnmf_clusters(all_jids.phone, all_maps.phone, chanlocs62, 'n_clus', K_phone, 'condition', 'phone', 'save_path', fig2_path);
        fprintf('Fig 2 done (K movie %d, K phone %d), figures in %s\n', K_movie, K_phone, fig2_path)
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
        prepare_limo_level_2_data
        fprintf('Fig 3 done, figures in %s/movie_vs_phone\n', figures_save_path)
    catch ME
        run_errors(end+1,:) = {'Fig 3', ME};
        fprintf(2, '\n%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    end
    close all
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
