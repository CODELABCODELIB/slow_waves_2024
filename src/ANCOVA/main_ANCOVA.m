% select subjects 
[participants,idx] = unique(cellfun(@(x) x(87:87+3),{res.pp},'UniformOutput',false));
% participant = participants{1}; 
% contains subject names and file names/numbers
subjects = readcell('/home/ruchella/slow_waves_2023/data/subjects.csv', "Delimiter", ",");
% contain sleep data
load('compile.mat');
% calculate sleep metrics per participant
% for pp=1:length(participants)
sleep = nan(1,length(participants));
sleep_day = nan(1,length(participants));
time_awake = nan(1,length(participants));
Y = nan(64,2,length(participants));
for pp=1:length(participants)
    % prepare the sleep data
    participant = participants{pp}; 
    participant_files = strcmp(subjects(:,1), participant);
    sel_subject_idx = contains([compile{:,1}],participant);
    try 
        sleep_times = compile{sel_subject_idx, 4};
        sleep_durations = compile{sel_subject_idx, 5};
    catch
        display('Sleep data for subject not found')
        continue 
    end
    
    sleep_metrics = calculate_sleep_metrics(participant_files,subjects,sleep_durations,sleep_times);
    % dependent variables
    tmp_res = res(ismember(cellfun(@(x) x(92:92+13), {res.pp}, 'UniformOutput', false),subjects(participant_files,4)));
    [features] = prepare_features_rate(tmp_res,1, 'plot',0);
    % independent variables 
    dates = subjects(participant_files,4); 
    sel_date = datetime(dates(ismember(dates,cellfun(@(x) x(92:92+13), {res.pp}, 'UniformOutput', false))), 'InputFormat', 'HH_mm_dd_MM_yy');
    if length(sel_date) >= 2
        sel_date = min(sel_date);
    end
    
    sel_sleep_metrics = sleep_metrics(year([sleep_metrics.experiment_date]) == year(sel_date) & month([sleep_metrics.experiment_date]) == month(sel_date) & day([sleep_metrics.experiment_date]) == day(sel_date));
    % [x] = create_design_matrix_ANCOVA(sel_sleep_metrics,size(features.density,2));
    sleep(pp) = sel_sleep_metrics.median_sleep;
    sleep_day(pp) = sel_sleep_metrics.sleep_durations(end);
    time_awake(pp) =  sel_sleep_metrics.time_awake_posix;

    Y(:,1,pp) = trimmean(features.density,20,2);
    Y(:,2,pp) = trimmean(features.amplitude,20,2);
    % f = median(,2, 'omitnan');
end
%% nan guard
sel_pps = ~(isnan(sleep) | isnan(sleep_day) | isnan(time_awake));
Y = Y(:,:,sel_pps);
sleep = sleep(sel_pps);
sleep_day = sleep_day(sel_pps);
time_awake = time_awake(sel_pps);
cont = [sleep;sleep_day;time_awake];
categorical = [zeros(1,size(Y,3));ones(1,size(Y,3))];
%%
[model] = ANCOVA(X',Y);
betas = (cellfun(@(x) x.betas,model,'UniformOutput',false));
betas = cat(3, betas{:});