function [selected_A] = pre_process_EEG_struct(A)
selected_A = {};
for pp=1:length(A)
    EEG = A{pp,2};
    [~,EEG.movie_indexes,EEG.movie_present] = find_movie_passive_event(EEG);
    if isfield(EEG.Aligned, 'merged')
        has_aligned_phone = isfield(EEG.Aligned.merged{1}, 'BS_to_tap') || isfield(EEG.Aligned.merged{2}, 'BS_to_tap');
        if isfield(EEG.Aligned.merged{1}, 'BS_to_tap') && isfield(EEG.Aligned.merged{2}, 'BS_to_tap')
           EEG.Aligned.merged_phone  = cat(2,EEG.Aligned.merged{1}.BS_to_tap.Phone, EEG.Aligned.merged{2}.BS_to_tap.Phone);
        elseif isfield(EEG.Aligned.merged{1}, 'BS_to_tap') && ~isfield(EEG.Aligned.merged{2}, 'BS_to_tap');
           EEG.Aligned.merged_phone = cat(2,EEG.Aligned.merged{1}.BS_to_tap.Phone,zeros(1,EEG.Aligned.merged_time(1))); 
        elseif ~isfield(EEG.Aligned.merged{1}, 'BS_to_tap') && isfield(EEG.Aligned.merged{2}, 'BS_to_tap');
           EEG.Aligned.merged_phone = cat(2,zeros(1,EEG.Aligned.merged_time(1)),EEG.Aligned.merged{2}.BS_to_tap.Phone); 
        end
        EEG.has_aligned_phone = has_aligned_phone;
    end
    if EEG.movie_present || isfield(EEG.Aligned, 'merged_phone')
        A{pp,2} = EEG;
        selected_A{pp} = A(pp,:);
    end
end
selected_A = cat(1,selected_A{:});
