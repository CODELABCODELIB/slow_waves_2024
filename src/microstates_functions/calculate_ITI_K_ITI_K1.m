function [dt_dt,taps] = calculate_ITI_K_ITI_K1(taps, options)
arguments 
    taps;
    options.log logical = 1;
    options.shuffle logical = 0;
end
if options.log && ~options.shuffle
    dt = log10(diff(taps))';
else
     dt = diff(taps)';
end
% since ITI's are differences the first and last taps do not have an ITI
% select the right taps where the labels will be based on
if options.shuffle
    [dt,taps] = shuffle_intervals(dt);
    dt = log10(dt);
    taps = taps(1:end-1);
else
    taps = taps(2:end-1);
end

dt_dt = [dt(1:end-1), dt(2:end)];
end