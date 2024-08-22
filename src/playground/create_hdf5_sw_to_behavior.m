%% create sw to behavior HDF5 file
for pp=1:size(res,2)
    tmp = zeros(64,2500);
    for chan=1:64
        taps_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).rate);
        triad_lengths_on_sw = assign_input_to_bin([res(pp).refilter.channels(chan).negzx{:}],res(pp).triad_lengths);
        rate_jid = cellfun(@(x,y) sum(x)/sum(y),taps_on_sw{chan},triad_lengths_on_sw{chan}, 'UniformOutput',0);
        tmp(chan,:) = [rate_jid{:}];
    end
    h5create(sprintf('%s/sw_to_behavior.h5',save_path),sprintf('/pp%d',pp),size(tmp))
    h5write(sprintf('%s/sw_to_behavior.h5',save_path),sprintf('/pp%d',pp),tmp)
end
