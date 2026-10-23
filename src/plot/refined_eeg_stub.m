function EEG = refined_eeg_stub(recording_info)
%% EEG struct without data from the recording_info saved by the refined SW pipeline
%
% **Usage:** EEG = refined_eeg_stub(recording_info)
%
% Same role as the EEG struct (without EEG.data) in the old checkpoints
% (get_eeg_structs): enough for seperate_movie_phone to find the movie events
% and phone taps on the native clock.
%
% Author: R.M.D. Kock, Leiden University, 2026
info = recording_info;
EEG = eeg_emptyset;
EEG.srate = info.srate; EEG.pnts = info.pnts; EEG.nbchan = 64;
EEG.trials = 1; EEG.xmin = info.xmin;
EEG.xmax = info.xmin + (info.pnts-1)/info.srate;
EEG.times = (info.xmin + (0:info.pnts-1)/info.srate)*1000;
EEG.event = info.event; EEG.urevent = info.urevent;
EEG.chanlocs = [];
if isfield(info, 'Aligned'); EEG.Aligned = info.Aligned; else; EEG.Aligned = struct(); end
if isfield(info, 'filename'); EEG.filename = info.filename; end
if isfield(info, 'filepath'); EEG.filepath = info.filepath; end
end
