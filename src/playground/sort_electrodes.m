function [sorted_names] = sort_electrodes(Orignalchanlocs)
X = round([Orignalchanlocs.X],4);
Z = round([Orignalchanlocs.Z],4);
Y = round([Orignalchanlocs.Y],4);
% Step 1: Sort by Y (left to right)
[sorted_proj_Y, idx_Y] = sort(Y, 'descend'); 
sorted_proj_X = X(idx_Y);
sorted_proj_Z = Z(idx_Y);
electrode_names = [1:length(Y)];
sorted_names = electrode_names(idx_Y);

% Step 2: Within each Y group, sort by X (front to back)
for i = 1:length(sorted_proj_Y)
    % Find electrodes with similar Y (e.g., small groups for same Y)
    close_in_Y = abs(sorted_proj_Y - sorted_proj_Y(i)) < 1e-6; % Adjust tolerance if necessary
    group_indices = find(close_in_Y); % Indices of the Y group
    [~, x_sort_idx] = sort(sorted_proj_X(group_indices), 'ascend'); % Sort by X (front to back)
    sorted_group_indices = group_indices(x_sort_idx);
    
    % Update sorted order
    sorted_proj_X(group_indices) = sorted_proj_X(sorted_group_indices);
    sorted_proj_Z(group_indices) = sorted_proj_Z(sorted_group_indices);
    sorted_names(group_indices) = sorted_names(sorted_group_indices);
end
end