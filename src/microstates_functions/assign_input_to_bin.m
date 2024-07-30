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

data = cell(64,1);
for chan=1:64
    JID = cell(50,50);
    for sel_tap=1:length(taps)
        tmp = input1{chan,sel_tap};
        if ~isempty(input2{chan,sel_tap})
            JID{gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)} = cat(2,tmp,JID{gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)});
            data{chan} = JID;
        end
    end
end