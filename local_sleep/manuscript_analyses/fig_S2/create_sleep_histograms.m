% Load the sleep data
load('sleepBeforeExp.mat');

%% Step 1: Compute mean sleep durations per day offset

% Number of participants
numParticipants = length(sleepBeforeExp);

% Initialize arrays to store participant IDs and mean sleep durations
participantIDs = cell(numParticipants, 1);
meanSleepDurationsPerParticipant = nan(numParticipants, 7); % Rows: participants, Columns: days before experiment (1 to 7)

% Process each participant
for p = 1:numParticipants
    participantData = sleepBeforeExp{p};
    participantID = participantData.ParticipantID;
    participantIDs{p} = participantID;
    
    % Initialize cell arrays to collect sleep durations for each day offset (1 to 7 days before experiment)
    sleepDurationsPerDayOffset = cell(7,1);
    
    % Get experiments for the participant
    experiments = participantData.Experiments;
    
    % Loop over each experiment
    for e = 1:length(experiments)
        experimentDate = experiments(e).ExperimentDate; % The date of the experiment
        sleepDates = experiments(e).SleepDates;         % Sleep dates within the 7-day window
        sleepDurations = experiments(e).SleepDurations; % Corresponding sleep durations
        
        % Loop over each sleep entry
        for s = 1:length(sleepDates)
            sleepDate = sleepDates(s);
            sleepDuration = sleepDurations(s);
            
            % Align both dates to the start of the day to ignore time components
            expDateStart = dateshift(experimentDate, 'start', 'day');
            sleepDateStart = dateshift(sleepDate, 'start', 'day');
            
            % Calculate the day offset (number of whole days before the experiment)
            dayOffset = days(expDateStart - sleepDateStart);
            dayOffset = floor(dayOffset); % Convert to integer days
            
            % Check if dayOffset is between 1 and 7
            if dayOffset >= 1 && dayOffset <= 7
                % Adjust indices to reverse order: dayOffset=1 -> index=7, dayOffset=7 -> index=1
                index = 8 - dayOffset;
                
                % Append the sleep duration to the corresponding day offset
                sleepDurationsPerDayOffset{index} = [sleepDurationsPerDayOffset{index}; sleepDuration];
            end
        end
    end
    
    % Compute the mean sleep duration for each day offset (excluding NaNs)
    meanSleepDurations = nan(1,7);
    for d = 1:7
        durations = sleepDurationsPerDayOffset{d};
        if ~isempty(durations)
            meanSleepDurations(d) = mean(durations, 'omitnan');
        end
    end
    
    % Store the mean sleep durations for the participant
    meanSleepDurationsPerParticipant(p,:) = meanSleepDurations;
end

%% Step 2: Plot histogram of median sleep durations across the 7 days before the experiment

% Compute the median sleep duration across the 7 days for each participant (excluding NaNs)
medianSleepDurations = median(meanSleepDurationsPerParticipant, 2, 'omitnan');

% Exclude participants with NaN median sleep durations
validIndicesMedian = ~isnan(medianSleepDurations);
validMedianSleepDurations = medianSleepDurations(validIndicesMedian);

% Define font sizes
fontSizeTitle = 20;
fontSizeLabels = 20;
fontSizeTicks = 20;

% Define figure size and make background transparent
figure('Position', [100, 100, 1600, 800], 'Color', 'white'); % [left, bottom, width, height] in pixels

% First histogram: median sleep durations
subplot(1,2,1);
histogramHandle1 = histogram(validMedianSleepDurations, ...
    'BinWidth', 0.5, ...
    'FaceColor', 'blue', ...          % Set face color to blue
    'EdgeColor', 'black', ...         % Set edge color to black for bar outlines
    'LineWidth', 2);                   % Set edge line width to 2
    
ax1 = gca;                           % Get current axes
ax1.FontSize = fontSizeTicks;        % Set tick labels font size
ax1.TickDir = 'out';                 % Make tick marks point outwards
ax1.Box = 'off';                     % Remove top and right axes
ax1.XAxisLocation = 'bottom';        % Ensure x-axis is at the bottom
ax1.YAxisLocation = 'left';          % Ensure y-axis is on the left
ax1.LineWidth = 2;                    % Set axes lines thickness
ax1.Color = 'none';                   % Make axes background transparent

% Add title and labels
titleHandle1 = title('Median Putative Sleep Duration in 7 Nights Before Experiment', ...
    'FontSize', fontSizeTitle, ...
    'FontWeight', 'bold');
xlabelHandle1 = xlabel('Putative Sleep Duration (Hours)', ...
    'FontSize', fontSizeLabels);
ylabelHandle1 = ylabel('Number of Participants', ...
    'FontSize', fontSizeLabels);

% Adjust label positions for better spacing
% Set Units to normalized to make positioning relative to the axes
xlabelHandle1.Units = 'normalized';
ylabelHandle1.Units = 'normalized';
titleHandle1.Units = 'normalized';

% Get current positions
xPos1 = xlabelHandle1.Position;
yPos1 = ylabelHandle1.Position;
titlePos1 = titleHandle1.Position;

% Shift x-axis label downward by 0.02 normalized units
xlabelHandle1.Position = [xPos1(1), xPos1(2)-0.02, xPos1(3)];

% Shift y-axis label leftward by 0.04 normalized units
ylabelHandle1.Position = [yPos1(1)-0.04, yPos1(2), yPos1(3)];

% Shift title upward by 0.05 normalized units
titleHandle1.Position = [titlePos1(1), titlePos1(2)+0.05, titlePos1(3)];

%% Step 3: Plot histogram of mean sleep durations for the day before the experiment

% Extract mean sleep duration for day offset 1 (day before the experiment)
% After reversing the indices, day offset 1 is at index=7
meanSleepDurationsDayBefore = meanSleepDurationsPerParticipant(:,7); % Index 7 corresponds to dayOffset=1

% Exclude participants with NaN mean sleep durations for the day before
validIndicesDayBefore = ~isnan(meanSleepDurationsDayBefore);
validMeanSleepDurationsDayBefore = meanSleepDurationsDayBefore(validIndicesDayBefore);

% Second histogram: mean sleep durations for the day before the experiment
subplot(1,2,2);
histogramHandle2 = histogram(validMeanSleepDurationsDayBefore, ...
    'BinWidth', 0.5, ...
    'FaceColor', 'blue', ...          % Set face color to blue
    'EdgeColor', 'black', ...         % Set edge color to black for bar outlines
    'LineWidth', 2);                   % Set edge line width to 2
    
ax2 = gca;                           % Get current axes
ax2.FontSize = fontSizeTicks;        % Set tick labels font size
ax2.TickDir = 'out';                 % Make tick marks point outwards
ax2.Box = 'off';                     % Remove top and right axes
ax2.XAxisLocation = 'bottom';        % Ensure x-axis is at the bottom
ax2.YAxisLocation = 'left';          % Ensure y-axis is on the left
ax2.LineWidth = 2;                    % Set axes lines thickness
ax2.Color = 'none';                   % Make axes background transparent

% Add title and labels
titleHandle2 = title('Putative Sleep Duration in Night Before Experiment', ...
    'FontSize', fontSizeTitle, ...
    'FontWeight', 'bold');
xlabelHandle2 = xlabel('Putative Sleep Duration (Hours)', ...
    'FontSize', fontSizeLabels);
ylabelHandle2 = ylabel('Number of Participants', ...
    'FontSize', fontSizeLabels);

% Adjust label positions for better spacing
% Set Units to normalized to make positioning relative to the axes
xlabelHandle2.Units = 'normalized';
ylabelHandle2.Units = 'normalized';
titleHandle2.Units = 'normalized';

% Get current positions
xPos2 = xlabelHandle2.Position;
yPos2 = ylabelHandle2.Position;
titlePos2 = titleHandle2.Position;

% Shift x-axis label downward by 0.02 normalized units
xlabelHandle2.Position = [xPos2(1), xPos2(2)-0.02, xPos2(3)];

% Shift y-axis label leftward by 0.04 normalized units
ylabelHandle2.Position = [yPos2(1)-0.04, yPos2(2), yPos2(3)];

% Shift title upward by 0.05 normalized units
titleHandle2.Position = [titlePos2(1), titlePos2(2)+0.05, titlePos2(3)];

%% Save the figure

% saveas(gcf, 'sleep_duration_histograms.png')
print(gcf, '-dsvg', 'sleep_duration_histograms.svg');