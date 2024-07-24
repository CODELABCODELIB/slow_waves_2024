
clearvars  -except A
EEG = A{1,2}{1,2};
sw = cell2mat(A{1, 2}{1, 4}.channels(1).negzx);
%% movie
EEG.data = zeros(64,length(EEG.times));
% upsampled to orginal freq for the right urevent and event indexes
[OUTEEG] = pop_resample(EEG, 1000);
% find the movie indexes in upsampled data
[~,movie_indexes] = find_movie_passive_event(OUTEEG);
% select the SW
movie_sw = sw(sw > movie_indexes.movie_latencies(1) & sw < movie_indexes.movie_latencies(end));
%% EEG
if isfield(EEG.Aligned, 'BS_to_tap')
    num_taps = size(find(EEG.Aligned.BS_to_tap.Phone == 1),2);
    [EEG] = add_events(EEG,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
    latencies = [EEG.event.latency];
    taps = latencies(strcmp({EEG.event.type}, 'pt'));
    [indexes] = find_gaps_in_taps(taps);
    sw_behavior = sw(sw > indexes{1}(1) & sw < indexes{1}(end));
    intersect(movie_indexes.movie_latencies(end),indexes{1})
end
%%
