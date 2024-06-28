
clearvars  -except A
EEG = A{1,3}{1,2};
% movie
latencies_movie = [EEG.urevent.latency]; 
[~,EEG.movie_indexes,EEG.movie_present] = find_movie_passive_event(EEG);
movie_indexes = EEG.movie_indexes.movie_latencies;
% EEG
if isfield(EEG.Aligned, 'BS_to_tap')
num_taps = size(find(EEG.Aligned.BS_to_tap.Phone == 1),2);
[EEG] = add_events(EEG,[find(EEG.Aligned.BS_to_tap.Phone == 1)],num_taps,'pt');
latencies = [EEG.event.latency]; 
taps = latencies(strcmp({EEG.event.type}, 'pt'));
[indexes] = find_gaps_in_taps(taps);

end