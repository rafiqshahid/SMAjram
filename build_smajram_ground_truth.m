% build_smajram_ground_truth.m 
%% SMAjram Ground-Truth Collector + Technical validity check
% Collects actual image filenames and their English class labels.
% Checks image-file readability, dimensions, extensions, and technical validity.
%
% Output:
%   - Ground Truth Excel: [file name, label]
%   - Technical Specs Excel: [file name, width, height, channels, bit_depth]
%
% The source folder, output workbook, and worksheet are configurable.
% Images in subfolders are included automatically.

%% User configuration

rootdir = 'your root directory';  % Dataset parent directory
folder = 'your folder';               % Selected dataset folder

excel_name = 'your excel.xlsx';     % Output Ground Truth Excel workbook
sheetname = 'your sheet';                % Ground Truth worksheet

tech_excel_name = 'SMAjram_TechSpecs.xlsx'; % SEPARATE output for technical specs
tech_sheetname = 'Specs_2';                 % Technical specs worksheet

bad_files_excel = 'SMAjram_BadFiles.xlsx';

%% Prepare source path

source_path = fullfile(rootdir, folder);

if ~isfolder(source_path)
    error('Source folder does not exist: %s', source_path);
end


%% Collect image files

imds = imageDatastore(source_path, 'IncludeSubfolders', true);
all_files = imds.Files;

if isempty(all_files)
    error('No supported image files found in: %s', source_path);
end

num_files = numel(all_files);

fprintf('Source folder: %s\n', source_path);
fprintf('Image files found: %d\n\n', num_files);


%% Check image integrity & technical validity

fprintf('Performing comprehensive image validation checks...\n');

bad_files = strings(0,1);
bad_reasons = strings(0,1);

% Preallocate arrays to store technical properties
widths = zeros(num_files, 1);
heights = zeros(num_files, 1);
channels = zeros(num_files, 1);
bit_depths = zeros(num_files, 1);

for i = 1:num_files
    current_file = all_files{i};
    [~, ~, ext] = fileparts(current_file);
    
    try
        if ~isfile(current_file)
            error('File does not exist.');
        end

        % 1. Header & Extension Validation
        info = imfinfo(current_file);
        expected_fmt = lower(erase(ext, '.'));
        actual_fmt = lower(info.Format);
        
        if strcmp(expected_fmt, 'jpg'), expected_fmt = 'jpeg'; end
        if strcmp(actual_fmt, 'jpg'), actual_fmt = 'jpeg'; end
        
        if ~strcmp(expected_fmt, actual_fmt)
            error('Extension Mismatch: Extension is %s but internal format is %s.', ext, info.Format);
        end

        % 2. Dimension & Resolution Validity
        if info.Width <= 0 || info.Height <= 0
            error('Invalid Dimensions: Image has zero or negative resolution (%dx%d).', info.Width, info.Height);
        end

        % 3. Readability & Content Anomalies
        img = imread(current_file);
        
        % 4. Data Validity (Blank / Broken Data Checks)
        if min(img(:)) == max(img(:))
            error('Technical Anomaly: Image is completely blank/flat (Zero Variance).');
        end
        
        % Save verified metrics if the try block succeeds
        widths(i) = info.Width;
        heights(i) = info.Height;
        channels(i) = size(img, 3);
        bit_depths(i) = info.BitDepth;

    catch ME
        bad_files(end+1,1) = string(current_file);
        bad_reasons(end+1,1) = string(ME.message);
    end

    if mod(i, 10000) == 0 || i == num_files
        fprintf('Checked %d / %d files\n', i, num_files);
    end
end


% Stop and log errors if any image fails technical validation
if ~isempty(bad_files)
    fprintf('\nWARNING: %d file(s) failed the technical validation check.\n', numel(bad_files));

    bad_files_table = table(bad_files, bad_reasons, 'VariableNames', {'FilePath', 'FailureReason'});
    writetable(bad_files_table, bad_files_excel);

    error(['Technical check failed. Detailed problem reasons were saved to ' ...
        '%s. Ground truth was not generated.'], bad_files_excel);
end

fprintf('Integrity and technical checks passed: all files are clean.\n\n');


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
    fprintf('\nWARNING: %d filename(s) have no extractable label.\n', numel(unmatched_files));
    disp(unmatched_files(1:min(10,numel(unmatched_files))));
    error('Ground truth was not generated. Check the unmatched filenames.');
end


%% Construct Separate Output Tables

metadata_struct = [raw_matches{:}];
labels = string({metadata_struct.label})';

% 1. Clean Ground-Truth Table (Only original 2 columns)
groundTruthTable = table(file_names, labels, ...
    'VariableNames', {'file name', 'label'});

% 2. Separate Technical Specifications Table
techSpecsTable = table(file_names, widths, heights, channels, bit_depths, ...
    'VariableNames', {'file name', 'width', 'height', 'channels', 'bit_depth'});


%% Export to Respective Excel Files

% Export Ground Truth
writetable(groundTruthTable, excel_name, 'Sheet', sheetname);

% Export Technical Specs
writetable(techSpecsTable, tech_excel_name, 'Sheet', tech_sheetname);


%% Report completion

fprintf('\n==================================================\n');
fprintf('Ground-Truth & Technical Validation Completed Successfully\n');
fprintf('==================================================\n');
fprintf('Integrity & Validity Check : PASSED (All files healthy)\n');
fprintf('Total Dataset Records     : %d\n\n', height(groundTruthTable));

fprintf('--- Output Files Generated ---\n');
fprintf('1. Ground Truth File      : %s (Sheet: %s)\n', excel_name, sheetname);
fprintf('2. Technical Specs File   : %s (Sheet: %s)\n', tech_excel_name, tech_sheetname);
fprintf('==================================================\n\n');
