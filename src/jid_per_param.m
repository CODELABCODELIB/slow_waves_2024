function [jid_param,param_per_triad,not_occupied_bins] = jid_per_param(twa,selected_waves,dt_dt, f,triad_lengths,options)
arguments
    twa;
    selected_waves;
    dt_dt;
    f = [];
    triad_lengths = [];
    options.sel_field char = '';
    options.pool_method char = 'none';
end
if isempty(f) && isempty(triad_lengths)
    error('Provide triad lengths')
end

param_per_triad = cell(length(twa),1);
jid_param = cell(length(twa),1);
if ~isempty(f)
    [param] = f(twa, 'pool_method', options.pool_method,'sel_field',options.sel_field);
end

[dt_dt,gridx,xi] = assign_tap2bin(dt_dt);
not_occupied_bins = reshape(~ismember(xi, dt_dt(:,3:4),'rows'),50,50);
for chan=1:length(twa)
    tmp_taps = selected_waves(chan,:);
    JID = NaN(50,50);
    % calculate the density 
    if isempty(f)
        tmp_taps = cellfun(@(triad) sum(triad),tmp_taps);
        [pooled,duplicates] = pool_duplicates(dt_dt,tmp_taps, 'pool_method','sum');
        pooled(pooled == 0) = NaN;
        pooled = pooled./cellfun(@(sel_tap) length(sel_tap), duplicates);
        pooled = pooled./triad_lengths;
        param_per_triad{chan} = pooled;
        pooled(isnan(pooled)) = 0;
    else
        tmp_param = [param{chan}];
        param_per_triad{chan} = cellfun(@(tap) median(tmp_param(tap)),tmp_taps);
        % param_per_triad{chan}(isnan([param_per_triad{chan}])) = 0;
        [pooled] = pool_duplicates(dt_dt,[param_per_triad{chan}], 'pool_method','median'); % pool multiple values in each bi
        % pooled(pooled == 0) = NaN;
    end
    for sel_tap=1:size(pooled,1)
        JID(gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)) = pooled(sel_tap);
    end
    JID(not_occupied_bins) = NaN;
    jid_param{chan} = JID;
end
end