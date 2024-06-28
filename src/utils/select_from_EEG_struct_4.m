function [matching_fields] = select_from_EEG_struct_4(all_eeg_structs,EEG)
matching_fields = 1;
if ~isempty(all_eeg_structs)
    matching_fields = isequal(fieldnames(all_eeg_structs(1)),fieldnames(EEG));
end
end