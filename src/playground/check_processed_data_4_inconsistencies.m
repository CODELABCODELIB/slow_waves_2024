% load the file
data_path = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sws_2025_features/durations.txt';
fieldnames = {'checkpoint','pp','phone','movie', 'phone_end', 'phone_start','movie_end', 'movie_start'};
T = readtable(data_path);
T.Properties.VariableNames = fieldnames;
s = table2struct(T);
[c,idx] = unique({s.pp});
s = s(idx);
%
phone_durations = round(([s.phone_end]-[s.phone_start])/60000);
figure; histogram(phone_durations)
figure; histogram(round([s.movie]))