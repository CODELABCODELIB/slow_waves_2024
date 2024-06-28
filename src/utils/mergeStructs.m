function [merged_struct] = mergeStructs(struct_a,struct_b)
%% Merge two structs
%
% **Usage**: [merged_struct] = mergeStructs(struct_a,struct_b)
% 
% Input(s): 
%   - struct_a: Struct to merge
%   - struct_b: Struct to merge
% Output(s): 
%   - merged_struct: Merged Struct


% If one of the structres is empty do not merge
if isempty(struct_a)
    merged_struct=struct_b;
    return
end
if isempty(struct_b)
    merged_struct=struct_a;
    return
end

%% insert struct a
merged_struct=struct_a;
%% insert struct b
size_a=length(merged_struct);
for j=1:length(struct_b)
    f = fieldnames(struct_b);
    for i = 1:length(f)
        merged_struct(size_a+j).(f{i}) = struct_b(j).(f{i});
    end
end
 end