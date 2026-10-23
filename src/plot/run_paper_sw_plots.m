%% Paper SW-to-behaviour figures from the refined-ICA rerun
% Builds res from Outputs/<id>/refined/wave_results.mat (build_refined_res),
% one recording per participant (participant_selection), and runs
% prepare_sw_data_for_plotting (population plots) and sw_to_behavior_plots.
%
% Run on the server:
%   nohup matlab -batch "run('<repo>/src/plot/run_paper_sw_plots.m')" > plots.out 2>&1 &
%
% res is cached in <output_root>/plot_data/res_refined.mat; delete it to rebuild.
% output_root and max_datasets can be set before running, e.g. a test run:
%   max_datasets = 2; run('<repo>/src/plot/run_paper_sw_plots.m')
%% settings
if ~exist('output_root','var'); output_root = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sw_refined_ica_rerun'; end
figures_save_path = sprintf('%s/figures',output_root);
plot_data_path = sprintf('%s/plot_data',output_root);
data_save_path = output_root; % prepare_sw_data_for_plotting saves in <data_save_path>/plot_data
save_string = ''; % no extra subfolder in sw_to_behavior_plots
if ~exist('max_datasets','var'); max_datasets = Inf; end % e.g. 2 for a test run (test runs are not cached)
%% add folders to paths (this repo, EEGLAB and taps2JID)
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))))
addpath(genpath('/home/ruchella/imports'))
addpath(genpath('/home/ruchella/TapDataAnalysis'))
%% create output folders
for folder = {figures_save_path, plot_data_path, sprintf('%s/pop',figures_save_path), ...
        sprintf('%s/sw_to_behavior',figures_save_path), sprintf('%s/rates',figures_save_path)}
    if ~exist(folder{1}, 'dir'); mkdir(folder{1}); end
end
set(0, 'DefaultFigureVisible', 'off');
%% res for the selected recordings (one per participant), cached in plot_data/res_refined.mat
[res, EEG] = build_refined_res(output_root, 'plot_data_path', plot_data_path, 'max_datasets', max_datasets);
%% population plots
prepare_sw_data_for_plotting
%% individual plots
sw_to_behavior_plots
close all
fprintf('Figures saved in %s\n', figures_save_path)
