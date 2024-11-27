function [experimentResult] = calculate_sleep_metrics(participantRows,dataCellArray,sleepData)
%% calculate sleep metrics night before and 7 nights before experiment
%
% **Usage:** [experimentResult] = calculate_sleep_metrics(participantRows,dataCellArray,sleepData)
%
% Input(s):
%   - participantRows = logical index file rows
%   - dataCellArray = participant folder and file names
%   - sleepData = Sleep times per day
%
% Output(s):
%   - experimentResult = 
%
% Author: David Hoff, Leiden University, 2024 
%
experimentStartTimes = cell2mat(dataCellArray(participantRows, 2)); % UNIX timestamps
experimentDates = datetime(experimentStartTimes, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
experimentDates.TimeZone = ''; % Remove time zone for consistency
experimentDays = unique(datetime(year(experimentDates), month(experimentDates), day(experimentDates))); % Unique experiment dates without time

experimentResult = struct();
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
    experimentResult(ed).ExperimentDate = experimentDate;
    experimentResult(ed).SleepDates = relevantSleepDates;
    experimentResult(ed).SleepDurations = relevantSleepDurations;
end