function blink_count = count_blinks_in_intervals(blinks, intervals)
    blink_count = 0;
    for i = 1:length(blinks)
        for j = 1:size(intervals, 1)
            if blinks(i) >= intervals(j,1) && blinks(i) <= intervals(j,2)
                blink_count = blink_count + 1;
                break; % A blink can only be in one interval, so we can break the loop once found
            end
        end
    end
end