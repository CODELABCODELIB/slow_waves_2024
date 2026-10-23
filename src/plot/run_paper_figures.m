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
%
% Outputs: <output_root>/paper_figures/{fig1,fig2,fig3}, data in <output_root>/paper_data.
% res is shared with run_paper_sw_plots.m (cached in <output_root>/plot_data/res_refined.mat).
%% settings
if ~exist('output_root','var'); output_root = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sw_refined_ica_rerun'; end
if ~exist('do_sw_plots','var'); do_sw_plots = 1; end % pop / sw_to_behavior / rates (as run_paper_sw_plots.m)
if ~exist('do_fig1','var'); do_fig1 = 1; end
if ~exist('do_fig2','var'); do_fig2 = 1; end
if ~exist('do_fig3','var'); do_fig3 = 1; end
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
figures_root = sprintf('%s/paper_figures',output_root);
paper_data = sprintf('%s/paper_data',output_root);
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
addpath(genpath(eeglab_dir))
addpath(genpath(tapdata_dir))
addpath(fullfile(repo_root,'local_sleep','manuscript_analyses','fig_1'))
for folder = {figures_root, paper_data}
    if ~exist(folder{1}, 'dir'); mkdir(folder{1}); end
end
set(0, 'DefaultFigureVisible', 'off');
rng(2026) % NNMF and k-means are randomly initialised
%% res for the selected recordings (Fig 2 and 3), same as run_paper_sw_plots.m
[res, EEG] = build_refined_res(output_root);
chanlocs62 = EEG.chanlocs;
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% SW to behavior plots (pop, rates, ...) %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_sw_plots
    figures_save_path = sprintf('%s/figures',output_root);
    data_save_path = output_root; % prepare_sw_data_for_plotting saves in <data_save_path>/plot_data
    save_string = ''; % no extra subfolder in sw_to_behavior_plots
    for folder = {sprintf('%s/pop',figures_save_path), sprintf('%s/sw_to_behavior',figures_save_path), ...
            sprintf('%s/rates',figures_save_path), sprintf('%s/plot_data',data_save_path)}
        if ~exist(folder{1}, 'dir'); mkdir(folder{1}); end
    end
    prepare_sw_data_for_plotting
    sw_to_behavior_plots
    close all
    fprintf('SW to behavior plots done, figures in %s\n', figures_save_path)
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_fig1
    addpath(fieldtrip_dir); ft_defaults;
    fig1_path = sprintf('%s/fig1',figures_root);
    fig1_data = sprintf('%s/fig1',paper_data);
    if ~exist(fig1_path,'dir'); mkdir(fig1_path); end
    % neighbours used by condition_contrast_v2 (distance 0.55 in chanlocs units)
    xyz = [[chanlocs62.X]',[chanlocs62.Y]',[chanlocs62.Z]'];
    n_neighbours = sum(squareform(pdist(xyz)) < 0.55, 2) - 1;
    fprintf('Fig 1 neighbours per channel (distance < 0.55): min %d, median %d, max %d\n', ...
        min(n_neighbours), median(n_neighbours), max(n_neighbours));
    if median(n_neighbours) < 2
        warning('Almost no neighbours at 0.55: chanlocs units differ from the old chanlocs.mat; clusters will not form.');
    end
    % recording selection of the paper: longest phone period per participant, movie < 80 min, phone >= 15 min
    build_top10_SWs_refined(output_root, fig1_data);
    previous_dir = pwd;
    cd(fig1_path) % topoplots are saved under pwd
    sw_pars = sw_pars_per_participant_v3(fig1_data, true, chanlocs62, ...
        'target_path', fig1_data, 'exclude_channels', [], 'interpolate_outliers', false);
    save(sprintf('%s/sw_pars.mat',fig1_data), 'sw_pars', '-v7.3');
    aggregated_sw_pars = aggregate_sw_pars_v2(sw_pars, @mean, chanlocs62, 'exclude_channels', []);
    save(sprintf('%s/aggregated_sw_pars.mat',fig1_data), 'aggregated_sw_pars', '-v7.3');
    [t_vals, sign_ch] = condition_contrast_v2(sw_pars, chanlocs62, 'exclude_channels', []);
    t_test_results.t_vals = t_vals; t_test_results.sign_ch = sign_ch;
    save(sprintf('%s/t_test_results.mat',fig1_data), 't_test_results', '-v7.3');
    cd(previous_dir)
    close all
    fprintf('Fig 1 done: %d participants, figures in %s\n', numel(fieldnames(sw_pars)), fig1_path)
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_fig2
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
        kmeans_error = zeros(1,10);
        for n_clus=1:10
            [~,~,~,~,kmeans_error(n_clus)] = cluster(jids', 'modkmeans', 0, 'n_clus',n_clus, 'numreps',100);
        end
        evaluation = evalclusters(jids',"kmeans","silhouette","KList",1:10);
        h = figure;
        tiledlayout(1,2)
        nexttile; plot(1:10,kmeans_error,'-o'); xlabel('K'); title(sprintf('k-means error %s',conditions{i}))
        nexttile; plot(evaluation); title(sprintf('silhouette %s',conditions{i}))
        saveas(h, sprintf('%s/k_selection_%s.svg',fig2_path,conditions{i}))
        close(h)
    end
    plot_nnmf_clusters(all_jids.movie, all_maps.movie, chanlocs62, 'n_clus', K_movie, 'condition', 'movie', 'save_path', fig2_path);
    plot_nnmf_clusters(all_jids.phone, all_maps.phone, chanlocs62, 'n_clus', K_phone, 'condition', 'phone', 'save_path', fig2_path);
    fprintf('Fig 2 done (K movie %d, K phone %d), figures in %s\n', K_movie, K_phone, fig2_path)
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if do_fig3
    addpath(genpath(limo_dir))
    figures_save_path = sprintf('%s/fig3',figures_root);
    limo_save_path = sprintf('%s/GLM_movie_vs_behavior',paper_data);
    prepare_limo_level_2_data
    close all
    fprintf('Fig 3 done, figures in %s/movie_vs_phone\n', figures_save_path)
end
