
%% SMAjram Ground-Truth Collector
% Collects actual image filenames and their English class labels.
% Checks image-file readability before generating ground truth.
%
% Output columns:
%   file name
%   label
%
% The source folder, output workbook, and worksheet are configurable.
% Images in subfolders are included automatically.


%% User configuration

rootdir = '' % D:\MATALBWork\DEREWork\';  % Dataset parent directory
folder = 'NineBlur_2';               % Selected dataset folder

excel_name = 'SMAjram_GT_3.xlsx';     % Output Excel workbook
sheetname = 'Blur_2';                % Output worksheet

bad_files_excel = 'SMAjram_BadFiles.xlsx';

%% Prepare source path

source_path = fullfile(rootdir, folder);

if ~isfolder(source_path)
    error('Source folder does not exist: %s', source_path);
end


%% Collect image files

imds = imageDatastore(source_path, ...
    'IncludeSubfolders', true);

all_files = imds.Files;

if isempty(all_files)
    error('No supported image files found in: %s', source_path);
end

num_files = numel(all_files);

fprintf('Source folder: %s\n', source_path);
fprintf('Image files found: %d\n\n', num_files);


%% Check image-file integrity

fprintf('Checking image-file readability...\n');

bad_files = strings(0,1);

for i = 1:num_files

    try
        if ~isfile(all_files{i})
            error('File does not exist.');
        end

        % Attempt to decode the image.
        imread(all_files{i});

    catch
        bad_files(end+1,1) = string(all_files{i});
    end

    if mod(i,10000) == 0 || i == num_files
        fprintf('Checked %d / %d files\n', i, num_files);
    end

end


% Stop if any image fails the check

if ~isempty(bad_files)

    fprintf('\nWARNING: %d file(s) failed the integrity check.\n', ...
        numel(bad_files));

    bad_files_table = table( ...
        bad_files, ...
        'VariableNames', {'FilePath'});

    writetable(bad_files_table, bad_files_excel);

    error(['Integrity check failed. Problematic file paths were saved to ' ...
        '%s. Ground truth was not generated.'], bad_files_excel);

end

fprintf('Integrity check passed: all files were readable.\n\n');


%% Extract filenames

[~, file_names, file_exts] = fileparts(all_files);

file_names = string(file_names) + string(file_exts);


%% Extract English class labels

% Expected filename:
% g00000310(B11)(A0)(s100){Adobe Arabic}_Naon.png

pattern = '_(?<label>[^_\.]+)\.[^.]+$';

raw_matches = regexpi(cellstr(file_names), pattern, 'names');

valid_idx = ~cellfun(@isempty, raw_matches);


% Report filenames with unmatched labels

if any(~valid_idx)

    unmatched_files = file_names(~valid_idx);

    fprintf('\nWARNING: %d filename(s) have no extractable label.\n', ...
        numel(unmatched_files));

    disp(unmatched_files(1:min(10,numel(unmatched_files))));

    error('Ground truth was not generated. Check the unmatched filenames.');

end


%% Construct ground-truth table

metadata_struct = [raw_matches{:}];

labels = string({metadata_struct.label})';

metadataTable = table( ...
    file_names, labels, ...
    'VariableNames', {'file name', 'label'});


%% Export ground truth to Excel

writetable(metadataTable, excel_name, 'Sheet', sheetname);


%% Report completion

fprintf('\nGround-truth collection completed successfully.\n');
fprintf('Integrity check: passed\n');
fprintf('Records written: %d\n', height(metadataTable));
fprintf('Output workbook: %s\n', excel_name);
fprintf('Worksheet: %s\n\n', sheetname);
