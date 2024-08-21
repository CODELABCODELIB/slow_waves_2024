function [data] = assign_input_to_bin(taps,input1,dt_dt,gridx,input2)
arguments
    taps;
    input1;
    dt_dt = [];
    gridx = [];
    input2 = input1;
end
if isempty(dt_dt) || isempty(gridx)
    [dt_dt,taps] = calculate_ITI_K_ITI_K1(taps);
    [dt_dt,gridx] = assign_tap2bin(dt_dt);
end

data = cell(size(input1,1),1);
for chan=1:size(input1,1)
    JID = cell(50,50);
    % JID = cellfun(@(x) NaN, num2cell(ones(50,50)), 'UniformOutput', false);
    for sel_tap=1:length(taps)
        tmp = input1{chan,sel_tap};
        if ~isempty(input2{chan,sel_tap})
            JID{abs(gridx - dt_dt(sel_tap,3)) < 0.0001,abs(gridx - dt_dt(sel_tap,4)) < 0.0001} = cat(2,tmp,JID{abs(gridx - dt_dt(sel_tap,3)) < 0.0001,abs(gridx - dt_dt(sel_tap,4)) < 0.0001});
            data{chan} = JID;
        end
    end
end