participants  = unique(cellfun(@(x) x(87:87+3),{res.pp},'UniformOutput',false));
participant = participants{1}; 

% contains subject names and file names/numbers
subjects = readcell('/home/ruchella/slow_waves_2023/data/subjects.csv', "Delimiter", ",");
load('compile.mat');

participant_files = strcmp(subjects(:,1), participant);
sleepData = compile{contains([compile{:,1}],participant), 5};

[sleep_durations] = calculate_sleep_metrics(participant_files,subjects,sleepData);