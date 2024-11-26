function [rhos,ps] = calculate_delayed_corr(features)
for feature={'amplitude', 'density'}
    % prepare data
    n_delays = 5;
    rho = nan(64,(n_delays*2)+1);
    p = nan(64,(n_delays*2)+1);
    
    for delay=1:(n_delays*2)+1
        % 1 to 5 is delay after
        if delay <= n_delays
            tmp_feature = zeros(size(features.(feature{:})));
            tmp_feature(:,1:size(tmp_feature,2)-delay+1) = features.(feature{:})(:,delay:end);
        elseif delay > n_delays+1
        % 6 to end is delay before
            tmp_feature = zeros(size(features.(feature{:})));
            tmp_feature(:,1+delay:end) = features.(feature{:})(:,1:end-delay);
        else
            tmp_feature = features.(feature{:});
        end
        % calculte the correlation per electrode 
        for chan=1:64
            [rho(chan,delay),p(chan,delay)] = corr(features.rate(chan,:)',tmp_feature(chan,:)', 'Type', 'Spearman', 'rows','complete');
        end
    end
    % assign results 
    rhos.(feature{:}) = rho;
    ps.(feature{:}) = p;
end