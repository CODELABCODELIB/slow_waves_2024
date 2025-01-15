function [res] = sw_detection_main(load_data,options)
%% Calculate SW to behavior features for all participants
%
% **Usage:**
%   -  sw_detection_main(load_data)
%   -  sw_detection_main(...,'save_results', 1, 'save_path','mydir', 'file', 'subject_2')
%   -  sw_detection_main(...,'parameter',2)
%
%  Input(s):
%   - taps = tap indexes
%
%  Optional Input(s):
%   - save_results (Default : 1) = 1 save results, 0 otherwise
%   - save_path (Default : current directory) = string path to save results
%   - file (Default: empty) = Unique checkpoint file name to save results
%   - parameter (Default : 1) = number of minutes to select after a triad for post_rate and pre_rate
%
%  Output(s):
%   - res = struct array with the sw to behavior features containing the following fields:
%       taps = indexes of phone taps
%       refilter = slow waves for all channels
%       rate = the number of taps during a SW triad
%       post_rate = the number of taps x min minutes after a SW triad
%       pre_rate = the number of taps x min minutes before a SW triad
%       latency = the latency to next tap following a SW triad
%
% Author: R.M.D. Kock, Leiden University, 2024
arguments
    load_data;
    options.save_results logical = 1;
    options.save_path char = '.';
    options.file = '';
    options.parameter = 1;
    options.remove_EEG = 1;
    options.pt = 0;
end

res = struct();
[load_data] = pre_process_EEG_struct(load_data);
for pp=1:size(load_data,1)
    EEG = load_data{pp,2};
    participant = load_data{pp,1};
    res = sw_detection(EEG, participant, options);
    [filtered_EEG] = pop_eegfiltnew(EEG, 1, 4);
    for chan=1:64
        sw_durations_1 = cellfun(@(x,y) x:y,res{1,4}.channels(chan).negzx,res{1,4}.channels(chan).wvend,'UniformOutput',false);
        sw_durations_2 = cellfun(@(x,y) x:x+2000,res{1,4}.channels(chan).negzx,'UniformOutput',false);
        sw_durations_3 = cellfun(@(x) x-1000:x+1000,res{1,4}.channels(chan).poszx,'UniformOutput',false);
        sw_durations_4 = cellfun(@(x) x-1000:x+1000,res{1,4}.channels(chan).maxnegpk,'UniformOutput',false);
        sws_to_select_1 = cell2mat(cellfun(@(sw_event) all(sw_event<size(EEG.data,2)),sw_durations_1,'UniformOutput',false));
        sws_to_select_2 = cell2mat(cellfun(@(sw_event) all(sw_event<size(EEG.data,2)),sw_durations_2,'UniformOutput',false));
        sws_to_select_3 = cell2mat(cellfun(@(sw_event) all(sw_event<size(EEG.data,2)),sw_durations_3,'UniformOutput',false));
        sws_to_select_4 = cell2mat(cellfun(@(sw_event) all(sw_event<size(EEG.data,2)),sw_durations_4,'UniformOutput',false));
        for sw =1:length(sw_durations_1)
            if sws_to_select_1(sw)
                sws_1{chan,sw} = EEG.data(chan,sw_durations_1{sw});
                filtered_sws_1{chan,sw} = filtered_EEG.data(chan,sw_durations_1{sw});
            end
            if sws_to_select_2(sw)
                sws_2{chan,sw} = EEG.data(chan,sw_durations_2{sw});
                filtered_sws_2{chan,sw} = filtered_EEG.data(chan,sw_durations_2{sw});
            end
            if sws_to_select_3(sw)
                tmp = sw_durations_3{sw};
                sws_3{chan,sw} = EEG.data(chan,tmp(tmp>0));
                filtered_sws_3{chan,sw} = filtered_EEG.data(chan,tmp(tmp>0));
            end
            if sws_to_select_4(sw)
                tmp = sw_durations_4{sw};
                sws_4{chan,sw} = EEG.data(chan,tmp(tmp>0));
                filtered_sws_4{chan,sw} = filtered_EEG.data(chan,tmp(tmp>0));
            end
        end
    end
    sw_wave = struct();
    sw_wave.sws_1 = sws_1; sw_wave.sws_1 = sws_1; sw_wave.sws_3 = sws_3; sw_wave.sws_4 = sws_4;
    sw_wave.filtered_sws_1 = filtered_sws_1; sw_wave.filtered_sws_2 = filtered_sws_2; sw_wave.filtered_sws_3 = filtered_sws_3; sw_wave.filtered_sws_4 = filtered_sws_4;
    res{1,5} = sw_wave;
    if options.save_results
        save(sprintf('%s/%s_res_%d',options.save_path,options.file, pp),'res', '-v7.3')
    end
end