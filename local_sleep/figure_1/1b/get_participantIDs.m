% Define the directory path
directoryPath = '/Users/davidhof/Desktop/MSc/3rd Semester/Internship/Local Sleep Project/Study Figures/1c/Results V2/No outlier interpolation/Participant_Topoplots';

% Get a list of all folders in the directory that start with 'P'
dirInfo = dir(fullfile(directoryPath, 'P*'));

% Extract the names of the folders
names = {dirInfo.name};

% Trim the names to keep only the last four characters (i.e., the participant ID)
participantIDs = cellfun(@(x) x(max(end-3,1):end), names, 'UniformOutput', false);

% Save the participant IDs to a .mat file
save('participantIDs.mat', 'participantIDs');