function [experimentResult] = calculate_sleep_metrics(participantRows,dataCellArray,sleepDurationsUTC,sleepTimesUTC)
%% calculate sleep metrics night before and 7 nights before experiment
%
% **Usage:** [experimentResult] = calculate_sleep_metrics(participantRows,dataCellArray,sleep_durations,sleep_times)
%
% Input(s):
%   - participantRows = logical index file rows
%   - dataCellArray = participant folder and file names
%   - sleep_durations = Sleep durations per day
%   - sleep_times = Sleep times per day
%
% Output(s):
%   - experimentResult =
%
% Author: David Hoff, Leiden University, 2024
% Edited: Ruchella Kock, Leiden University, 2024
%
experimentStartTimes = cell2mat(dataCellArray(participantRows, 2)); % UNIX timestamps
experimentDates = datetime(experimentStartTimes, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
experimentDates.TimeZone = ''; % Remove time zone for consistency
experimentDays = unique(datetime(year(experimentDates), month(experimentDates), day(experimentDates))); % Unique experiment dates without time

experimentResult = struct();
% Loop over each unique experiment day
for ed = 1:length(experimentDays)
    % get the exact start time of the experiment
    [y,m,d] = ymd(experimentDates);
    exactExperimentStart = min(experimentDates(y==year(experimentDays(ed)) & m==month(experimentDays(ed)) & d==day(experimentDays(ed))));
    exactExperimentStartPosix = min(experimentStartTimes(y==year(experimentDays(ed)) & m==month(experimentDays(ed)) & d==day(experimentDays(ed))));

    experimentDate = experimentDays(ed);
    % Define the 7-day window before the experiment date
    startDate = dateshift(experimentDate - caldays(7), 'start', 'day'); % Start of the day 7 days before
    endDate = dateshift(experimentDate - caldays(1), 'end', 'day');     % End of the day 1 day before

    % Convert sleep data dates to MATLAB datetime
    % Adjusting for UNIX time in milliseconds
    sleepDates = datetime(sleepDurationsUTC.ddayutc / 1000, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
    sleepTimes = datetime(sleepTimesUTC.Wake_UTC / 1000 , 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
    % Remove time zone information if any
    sleepDates.TimeZone = '';
    sleepTimes.TimeZone = '';

    % Find sleep entries within the 7-day window
    startDate = datetime(year(startDate), month(startDate), day(startDate));
    endDate = datetime(year(endDate), month(endDate), day(endDate));

    sleepIndicesDurations = (sleepDates >= startDate) & (sleepDates <= endDate);
    % repeat the same for the data and times array but remove the time information
    % to be sure the selection is made on date only and not the times
    tmpSleepTime = sleepTimes;
    for i = 1:length(tmpSleepTime)
        tmpSleepTime(i) = datetime(year(tmpSleepTime(i)), month(tmpSleepTime(i)), day(tmpSleepTime(i)));
    end
    sleepIndicesTimes = (tmpSleepTime >= startDate) & (tmpSleepTime <= endDate);

    % Extract relevant sleep dates and durations
    relevantSleepDurations = sleepDurationsUTC.dx(sleepIndicesDurations);
    relevantSleepDates = sleepTimes(sleepIndicesTimes);
    relevantSleepDatesPosix = sleepTimesUTC.Wake_UTC(sleepIndicesTimes);

    % Store the results in a structure
    experimentResult(ed).experiment_date = exactExperimentStart;
    experimentResult(ed).sleep_dates = relevantSleepDates;
    experimentResult(ed).sleep_durations = relevantSleepDurations;
    experimentResult(ed).median_sleep = median(relevantSleepDurations, 'omitnan');
    experimentResult(ed).time_of_day = timeofday(exactExperimentStart);
    experimentResult(ed).time_of_day_hours = hours(experimentResult(ed).time_of_day) + minutes(experimentResult(ed).time_of_day)/60 + seconds(experimentResult(ed).time_of_day)/3600;
   % check if the sleep on the experiment data is missing 
    if day(relevantSleepDates(end)) == day(endDate) && month(relevantSleepDates(end)) == month(endDate) && year(relevantSleepDates(end)) == year(endDate)
        experimentResult(ed).time_awake = timeofday(exactExperimentStart) - timeofday(relevantSleepDates(end));
        experimentResult(ed).time_awake_posix = exactExperimentStartPosix*1000 - relevantSleepDatesPosix(end);
    else
        experimentResult(ed).time_awake = NaN;
        experimentResult(ed).time_awake_posix = NaN;
    end
end