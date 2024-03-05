function [jid_upslp,upslp_per_triad] = jid_per_param(twa,selected_waves,dt_dt, f,options)
arguments
    twa;
    selected_waves;
    dt_dt;
    f;
    options.sel_field = "mxupslp";
    options.pool_method = 'none';
end
upslp_per_triad = cell(length(twa),1);
jid_upslp = cell(length(twa),1);

[upslp] = calculate_slope(twa, 'sel_field',options.sel_field, 'pool_method', options.pool_method);
[dt_dt,gridx,xi] = assign_tap2bin(dt_dt);
not_occupied_bins = reshape(~ismember(xi, dt_dt(:,3:4),'rows'),50,50);
for chan=1:length(twa)
    tmp_taps = selected_waves(chan,:);
    tmp_param = [upslp{chan}];
    upslp_per_triad{chan} = cellfun(@(tap) median(tmp_param(tap)),tmp_taps);
    JID = zeros(50,50);
    [pooled] = pool_duplicates(dt_dt,[upslp_per_triad{chan}], 'pool_method','median'); % pool multiple values in each bi
    for sel_tap=1:size(pooled,1)
        JID(gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)) = pooled(sel_tap);
    end
    JID(not_occupied_bins) = NaN;
    jid_upslp{chan} = JID;
    % JID_reshaped = reshape(JID,2500,1);
end
end