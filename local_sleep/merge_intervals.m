function merged = merge_intervals(intervals)
    % Sort intervals by starting times
    intervals = sortrows(intervals);
    merged = intervals(1,:);
    
    for i = 2:size(intervals,1)
        prev = merged(end,:);
        curr = intervals(i,:);
        if prev(2) >= curr(1) % Overlapping intervals
            merged(end,2) = max(prev(2), curr(2)); % Merge
        else
            merged = [merged; curr]; % No overlap, add interval
        end
    end
end