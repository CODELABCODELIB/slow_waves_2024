function [files_grouped,folder] = gen_set_file_names(path,start_idx,end_idx, options)
%% Get names of files to read
%
% **Usage:** [files_grouped,folder] = gen_set_file_names(path,start_idx,end_idx)
%
%  Input(s):
%   - path = path to raw data folders
%   - start_idx = Folder number to start at
%   - end_idx = Folder number to end at
%
%  Output(s):
%   - files_grouped = File names to read
%   - folder = Folder names
%
% Author: R.M.D. Kock

arguments
    path char;
    start_idx double;
    end_idx double;
    options.all logical = 1;
    options.excludeRW logical = 1;
end
try 
    if options.all
        files_all = dir(sprintf('%s/**/*.set',path));
    else
        files_all = dir(sprintf('%s/DS*/*.set',path));
    end
    if options.excludeRW
        RW_participants = contains({files_all.folder}, 'RW');
        files_all = files_all(~RW_participants);
        DS_participants = contains({files_all.folder}, 'DS');
        files_all = files_all(~DS_participants);
    end
catch ME
    error(ME.message)
end
[folder, ~, ic] = unique({files_all.folder});
if ~(end_idx)
    end_idx = length(folder);
end

if start_idx ~= 1 || end_idx ~= length(folder)
    selected = ismember(ic, [start_idx:end_idx]);
    ic = ic(selected);
    files_all = files_all(selected);
    folder = unique({files_all.folder});
end

zz = table(ic,{files_all.name}',{files_all.folder}', 'VariableNames', {'ic', 'files', 'folder'});
table_grouped = unstack(zz, 'ic','files');

% get the file names
names = table_grouped.Properties.VariableNames;
names = names(1,2:end);
names = cellfun(@(x) sprintf('%s.set',x(2:end-4)) ,names,'UniformOutput' ,false);

logical_selection = table2cell(table_grouped);
logical_selection = ~isnan(cell2mat(logical_selection(:,2:end)));
files_grouped = {};
for i=1:size(logical_selection, 1)
    files_grouped{i} = {names{logical_selection(i,:)}};
end 
end