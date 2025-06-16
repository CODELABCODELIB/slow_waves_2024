function [res,selected_pps,s] = participant_selection(res)

data_path = '/mnt/ZETA18/User_Specific_Data_Storage/ruchella/slow_waves/sws_2025_features/durations.txt';
fieldnames = {'checkpoint','pp','phone','movie', 'phone_end', 'phone_start','movie_end', 'movie_start'};
T = readtable(data_path);
T.Properties.VariableNames = fieldnames;
s = table2struct(T);
[~,idx] = unique({s.pp});
s = s(idx);

participants = cellfun(@(x) x(87:90),{res.pp},'UniformOutput',false);
selected_pps = ones(size(participants,2),1);
for i=1:size(participants,2)
    tmp_sel = cellfun(@(x) isempty(x),strfind(participants, participants{i}));
    indexes = find(~tmp_sel);
    if length(indexes) == 2
        [~, phone_selection] = max([s(~tmp_sel).phone]);
        [max_movie, movie_selection] = max([s(~tmp_sel).movie]);
        if max_movie > 80
            [~, movie_selection] = min([s(~tmp_sel).movie]);
        end
        if max_movie > 80
            if movie_selection==2; select=1; else select=2; end;
            selected_pps(indexes(movie_selection)) = 0;
        else
            if phone_selection==2; select=1; else select=2; end;
            selected_pps(indexes(phone_selection)) = 0;
        end
    end
end
res = res(logical(selected_pps));
phone_size = cellfun(@(x) size(x,2), {res.behavior_sws});
res = res(phone_size > quantile(phone_size, [0.05]));
end