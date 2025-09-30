% Define the path to CSV file holding subject info
csvFilePath = 'subjects.csv';

% Read the CSV file into a cell array
dataCellArray = readcell(csvFilePath, "Delimiter", ",");

% Load participant IDs
load('participantIDs.mat');

% Load the sleep data
load('compile.mat');

%%

% Initialize an empty cell array to store the results
sleepBeforeExp = {}; % This will store the results for all participants

% Loop over each participant in 'participantIDs'
for p = 1:length(participantIDs)
    participantID = participantIDs{p}; % Get the current participant ID
    fprintf('Processing participant %s (%d of %d)\n', participantID, p, length(participantIDs));
    
    % Find the participant in the 'compile' object
    compileIndex = [];
    for t = 1:size(compile, 1)
        if isequal(compile{t,1}{1}, participantID)
            compileIndex = t;
            break;
        end
    end
    
    if isempty(compileIndex)
        fprintf('Participant %s not found in compile.\n', participantID);
        continue; % Skip to the next participant if not found
    end
    
    % Retrieve sleep data for the participant from 'compile'
    sleepData = compile{compileIndex, 5}; % 'cont' struct with fields 'dx' and 'ddayutc'
    
    % Find all experiment entries for the participant in 'dataCellArray'
    participantRows = strcmp(dataCellArray(:,1), participantID);
    if ~any(participantRows)
        fprintf('No experiments found for participant %s in dataCellArray.\n', participantID);
        continue; % Skip to the next participant if no experiments found
    end
    
    % Extract experiment start times (UNIX time) and convert to MATLAB datetime
    experimentStartTimes = cell2mat(dataCellArray(participantRows, 2)); % UNIX timestamps
    experimentDates = datetime(experimentStartTimes, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
    experimentDates.TimeZone = ''; % Remove time zone for consistency
    experimentDays = unique(datetime(year(experimentDates), month(experimentDates), day(experimentDates))); % Unique experiment dates without time
    
    % Prepare a structure to hold the participant's sleep data before experiments
    participantResults = struct();
    participantResults.ParticipantID = participantID;
    participantResults.Experiments = [];
    
    % Loop over each unique experiment day
    for ed = 1:length(experimentDays)
        experimentDate = experimentDays(ed);
        
        % Define the 7-day window before the experiment date
        startDate = dateshift(experimentDate - caldays(7), 'start', 'day'); % Start of the day 7 days before
        endDate = dateshift(experimentDate - caldays(1), 'end', 'day');     % End of the day 1 day before
        
        % Convert sleep data dates to MATLAB datetime
        % Adjusting for UNIX time in milliseconds
        sleepDates = datetime(sleepData.ddayutc / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
        
        % Remove time zone information if any
        sleepDates.TimeZone = '';
        
        % Find sleep entries within the 7-day window
        sleepIndices = (sleepDates >= startDate) & (sleepDates <= endDate);
        
        % Extract relevant sleep dates and durations
        relevantSleepDates = sleepDates(sleepIndices);
        relevantSleepDurations = sleepData.dx(sleepIndices);
        
        % Store the results in a structure
        experimentResult = struct();
        experimentResult.ExperimentDate = experimentDate;
        experimentResult.SleepDates = relevantSleepDates;
        experimentResult.SleepDurations = relevantSleepDurations;
        
        % Append the experiment result to the participant's results
        participantResults.Experiments = [participantResults.Experiments; experimentResult];
    end
    
    % Append the participant's results to the main results cell array
    sleepBeforeExp = [sleepBeforeExp; participantResults];
end

% Save the results to a .mat file
save('sleepBeforeExp.mat', 'sleepBeforeExp');