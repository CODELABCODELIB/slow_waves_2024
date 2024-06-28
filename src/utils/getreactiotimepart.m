function [tmpp_RT,indexes,isRT] = getreactiotimepart(EEG)
% [EEGSET RTSET] = getreactiotimepart(eeg_name, RT, direeg)
% Given a status file with .set file names, output the reaction time data
% If RT ONLY is set to true, the EEGSET is returened []
% Output
% EEGSET , In struct, truncated EEG data containing reaction time events only
% RTSET, In struct, reaction time events gathered in the data;
% The size of the struct is the same as number of EEG sessions
% EEGSET contains the EEG data
% Note, the EEG folder should be in direeg
% this

% go through urevent files, and extract sequence S 33  or S 36 > T 1_on T 1_off
%
% Author: Arko Ghosh, Leiden University
tmp_urevent = EEG.urevent;
tmp_type = {tmp_urevent.type};

tmp_log_stimR = strcmp('S 33', tmp_type);
tmp_log_stimL = strcmp('S 36', tmp_type);

tmp_log_pres = strcmp('T  1_on', tmp_type);
tmp_log_release = strcmp('T  1_off', tmp_type);
% extract the sequence for the RIGHT and left

tmp_right = and(and(tmp_log_stimR(1:end-2),tmp_log_pres(2:end-1)),tmp_log_release(3:end));
tmp_idx_right = find(tmp_right == true);

tmp_left = and(and(tmp_log_stimL(1:end-2),tmp_log_pres(2:end-1)),tmp_log_release(3:end));
tmp_idx_left = find(tmp_left == true);

% Is there RT data?
isRT = and(length(tmp_idx_right)>10, length(tmp_idx_left)>10);

% Extract the corresponding times S - Response Press - Response Release
tmp_timestamp = [tmp_urevent.latency];

% save the timestamps of : passive stimuli, start of touch, end of touch
tmp_rightRT = [tmp_timestamp(tmp_idx_right)' tmp_timestamp(tmp_idx_right+1)' tmp_timestamp(tmp_idx_right+2)'];
tmp_leftRT = [tmp_timestamp(tmp_idx_left)' tmp_timestamp(tmp_idx_left+1)' tmp_timestamp(tmp_idx_left+2)'];
tmpp_RT.RightRT = tmp_rightRT;
tmpp_RT.LeftRT = tmp_leftRT;

% index of the passive stimuli
indexes.right = tmp_idx_right;
indexes.left = tmp_idx_left;
end