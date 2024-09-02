save_path = '/home/ruchella/slow_waves_2023/data';
processed_data_path = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/Feb_2022_BS_to_tap_classification_EEG';
[files_grouped,folder] = gen_set_file_names(processed_data_path,1,114, 'excludeRW',0);
subjects = cell(length(files_grouped),2);
count =1;
for i=1:length(files_grouped)
    % file selection
    load(sprintf('%s/status.mat',folder{i}));
    sub = split(folder{i},'/');
    for file=1:length({eeg_name.processed_name})
        subjects{count,1} = sub{end};
        subjects{count,2} = int64(min([eeg_name(file).start]));
        subjects{count,3} = int64(min([eeg_name(file).stop]));
        subjects{count,4} = eeg_name(file).processed_name;
        count = count +1;
    end
end
% exclude RW subjects
subjects= subjects(~contains(subjects(:,1),'RW'),:);
% remove repeated rows
[~,idx] = unique(subjects(:,4), 'stable'); 
subjects = subjects(idx,:);
writecell(subjects,sprintf('%s/subjects.csv', save_path),'Delimiter', ',')