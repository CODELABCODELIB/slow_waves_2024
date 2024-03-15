function complement_intervals = get_complement_intervals(intervals, rec_duration)
    % Start with the entire range as the initial complement interval
    complement_intervals = [1, rec_duration];
    
    for i = 1:size(intervals, 1)
        new_complement_intervals = [];
        for j = 1:size(complement_intervals, 1)
            current_interval = complement_intervals(j,:);
            if intervals(i,1) <= current_interval(1) && intervals(i,2) >= current_interval(2)
                % The interval fully covers the current complement interval, remove it
                continue;
            elseif intervals(i,1) > current_interval(2) || intervals(i,2) < current_interval(1)
                % The interval does not intersect the current complement interval, keep it
                new_complement_intervals = [new_complement_intervals; current_interval];
            else
                % The interval partially overlaps, adjust the current complement interval
                if intervals(i,1) > current_interval(1)
                    new_complement_intervals = [new_complement_intervals; current_interval(1), intervals(i,1)-1];
                end
                if intervals(i,2) < current_interval(2)
                    new_complement_intervals = [new_complement_intervals; intervals(i,2)+1, current_interval(2)];
                end
            end
        end
        complement_intervals = new_complement_intervals;
    end
end