function [selected_A] = pre_process_EEG_struct(A)
selected_A = {};
for pp=1:length(A)
    EEG = A{pp,2};
    [~,EEG.movie_indexes,EEG.movie_present] = find_movie_passive_event(EEG);
    if isfield(EEG.Aligned, 'merged')
        has_aligned_phone = cellfun(@(x) isfield(x, 'BS_to_tap'), EEG.Aligned.merged);
        EEG.has_aligned_phone = any(has_aligned_phone);
        if EEG.has_aligned_phone
            EEG.Aligned.merged_phone = [];
            for i=1:length(has_aligned_phone)
                if ~has_aligned_phone(i)
                    EEG.Aligned.merged_phone= cat(2,EEG.Aligned.merged_phone, zeros(1,EEG.Aligned.merged_time(i)));
                else
                    EEG.Aligned.merged_phone= cat(2,EEG.Aligned.merged_phone, EEG.Aligned.merged{i}.BS_to_tap.Phone);
                end
            end
        end

    elseif isfield(EEG.Aligned, 'BS_to_tap')
        EEG.has_aligned_phone =1;
    else
        EEG.has_aligned_phone =0;
    end
    if EEG.movie_present || EEG.has_aligned_phone
        A{pp,2} = EEG;
        selected_A{pp} = A(pp,:);
    end
end
selected_A = cat(1,selected_A{:});
