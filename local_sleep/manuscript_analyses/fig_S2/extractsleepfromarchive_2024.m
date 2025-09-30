%This script extracts all the sleep values for subjects identified by
%subjects.xlxs 
% Arko Ghosh 26/09/2024
% The daily sleep values are noted. % note the timestamp is based on the
% 'day of the sleep onset' and 8 hours prior to the typical sleep onset
% according to cosinor. 

%% Get all QA ID based on Ruchella List

targetlist = readtable('G:\One_drive_ghosha2\OneDrive - Universiteit Leiden\PostBox\subjects.xlsx');
targetid = targetlist(:,1);
targetid_trim = unique(targetid);


%% Mass sheet 
Mass_sheet = '\\CODELABGAMMA\Users\aghos\OneDrive - fsw.leidenuniv.nl\Leiden_CODELAB\Feb_2018_Experiments\Documents_Subject_List_2018\Documents\MASS_Subject_list.xlsx';
%% Load processed sleep data

phonepath = 'G:\Data_deposit\Smartphone_pool';

%% Gather only what is needed
for t = 1:size(targetid_trim,1)
% Get participant ID 
[Age,Gender, Curfew, Height, Weight, ParticipantID] = getdemoinfo(targetid_trim{t,1}, Mass_sheet, [], 2);
compile{t,1} = targetid_trim{t,1}; 
compile{t,2} = ParticipantID; 
compile{t,3} = Curfew; % Mark if there is a curfew or not 
 tmp_Data= getTapDataParsed(ParticipantID{1,1},'deviceType', 'Phone', 'OS', 'Win' ...
            ,'RawDataDir', [phonepath,'\raw\folder'], ...
            'ParsedDataDir',[phonepath,'\parsed'],  'Refresh', 0);
[Sleeptap.Sleep_UTC,Sleeptap.Wake_UTC] = getresttimesphone_v2(tmp_Data, 60, 0, 0, 2, 10); close all % remove on-off
            [cont.dx, cont.ddayutc] = getdailysleepdur(Sleeptap, 8);
compile{t,4} = Sleeptap; % The sleep onset off UTC but not structured from one day to the next, structured as one sleep duration to the next. 
compile{t,5} = cont; % daily sleep with day of sleep ONSET noted: 8 hours before typical sleep onset - not to be confused with daily sleep onset

clear ParticipantID Age Gender Height Weight Sleeptap cont

end

%% Save the new output in postobox

save compile compile -v7.3 
