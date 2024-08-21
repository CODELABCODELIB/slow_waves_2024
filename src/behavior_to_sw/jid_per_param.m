function [jid_param,param_per_triad,not_occupied_bins] = jid_per_param(refilter,selected_waves,dt_dt, f,triad_lengths,options)
arguments
    refilter;
    selected_waves;
    dt_dt;
    f = [];
    triad_lengths = [];
    options.sel_field char = '';
    options.pool_method char = 'none';
    options.pool_duplicates logical = 1;
end
if isempty(f) && isempty(triad_lengths)
    error('Provide triad lengths')
end
tmp = zeros(1,length(selected_waves(1,:)));
param_per_triad = cell(length(refilter),1);
jid_param = cell(length(refilter),1);
if ~isempty(f)
    [param] = f(refilter, 'pool_method', options.pool_method,'sel_field',options.sel_field);
end

[dt_dt,gridx,xi] = assign_tap2bin(dt_dt);
not_occupied_bins = reshape(~ismember(xi, dt_dt(:,3:4),'rows'),50,50);
for chan=1:length(refilter)
    tmp_taps = selected_waves(chan,:);
    JID = NaN(50,50);
    % calculate the density 
    if isempty(f)
        tmp_taps = cellfun(@(triad) sum(triad),tmp_taps);
        [pooled,duplicates,duplicates_all] = pool_duplicates(dt_dt,tmp_taps, 'pool_method','sum');
        pooled(pooled == 0) = NaN;
        % pooled = pooled./cellfun(@(sel_tap) length(sel_tap), duplicates);

        for sel=1:length(triad_lengths)
            tmp(sel) = sum(triad_lengths(duplicates_all(sel,:)));
        end
        pooled = pooled./tmp;
        param_per_triad{chan} = pooled;
        pooled(isnan(pooled)) = 0;
    else
        tmp_param = [param{chan}];
        % select the parameter for all the sw happening in each triad
        param_per_triad{chan} = cellfun(@(tap) median(tmp_param(tap)),tmp_taps);
        % param_per_triad{chan}(isnan([param_per_triad{chan}])) = 0;
        if options.pool_duplicates
            pooled = pool_duplicates(dt_dt,[param_per_triad{chan}], 'pool_method','median'); % pool multiple values in each bi
        else
            pooled = [param_per_triad{chan}]';
        end
        % pooled(pooled == 0) = NaN;
    end
    for sel_tap=1:size(pooled,1)
        JID(gridx == dt_dt(sel_tap,3),gridx == dt_dt(sel_tap,4)) = pooled(sel_tap);
    end
    JID(not_occupied_bins) = NaN;
    jid_param{chan} = JID;
end
end