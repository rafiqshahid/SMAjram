%% SMAjram Blur Generation (Batch Version)
% Generates original and blurred versions of selected images from AjramRot.
%
% Each selected input image produces four outputs:
%   B00 = Original image
%   B11 = Disk filter, radius 1
%   B13 = Disk filter, radius 3
%   B15 = Disk filter, radius 5
%
% Batch configuration allows the full dataset to be generated folder by
% folder without editing the function's internal processing logic.
%
% IMPORTANT:
%   - img_list selects positions in the sorted source-file list, not IDs
%     embedded in the source filenames.
%   - Use non-overlapping img_list ranges for successive batches.
%   - Set output_id_start/output_id_end according to the SMAjram Gen Guide.
%   - This script does not implement automatic resume after interruption.

clear;
clc;

%% User Configuration

source_folder = 'RotE';
destination_folder = 'Ajram_Blur1';
img_type = '.png';

% Disk-filter radii used for blur generation
mask_size = [1 3 5];

% Select source images from the sorted rotation-file list.
% Configure this range and the global IDs for the intended batch.
img_list = 1:72000;

% Global output ID range for this batch (from the SMAjram Gen Guide)
output_id_start = 432001;
output_id_end   = 720000;
		
total_images = output_id_end - output_id_start + 1;

% Display options
show_progress = true;       % Show processing progress in Command Window
show_visuals = false;       % Display generated images during processing
progress_interval = 0.01;   % Progress update interval (0.01 = approximately 1%)

%% Prepare input and output

if ~isfolder(source_folder)
    error('Source folder does not exist: %s', source_folder);
end

% Restrict the source list to the requested image extension, then sort by
% filename so that source indices are deterministic across runs.
source = dir(fullfile(source_folder, ['*' img_type]));
if isempty(source)
    error('No %s images were found in source folder: %s', img_type, source_folder);
end
[~, sort_idx] = sort({source.name});
source = source(sort_idx);

num_source_files = numel(source);

if isempty(img_list) || ~isvector(img_list) || ...
        any(~isfinite(img_list)) || any(img_list ~= fix(img_list)) || ...
        any(img_list < 1) || any(img_list > num_source_files)
    error(['img_list must contain valid integer indices between 1 and %d ' ...
        'for the sorted source-file list.'], num_source_files);
end

if isempty(mask_size) || any(mask_size < 0) || any(mask_size ~= fix(mask_size))
    error('mask_size must contain nonnegative integer disk-filter radii.');
end

if ~isscalar(output_id_start) || ~isscalar(output_id_end) || ...
        output_id_start < 1 || output_id_end < output_id_start || ...
        output_id_start ~= fix(output_id_start) || ...
        output_id_end ~= fix(output_id_end)
    error('The output ID range must contain valid positive integers with end >= start.');
end

if total_images ~= output_id_end - output_id_start + 1
    error('total_images does not match the configured output ID range.');
end

num_input_images = numel(img_list);
num_outputs_per_input = numel(mask_size) + 1;
expected_output_count = num_input_images * num_outputs_per_input;

if expected_output_count ~= total_images
    error(['Batch configuration mismatch: %d input images x %d outputs per input ' ...
        '= %d expected outputs, but the configured ID range contains %d IDs. ' ...
        'Check img_list and the output ID range against the Gen Guide.'], ...
        num_input_images, num_outputs_per_input, expected_output_count, total_images);
end

if ~isfolder(destination_folder)
    mkdir(destination_folder);
end

fprintf('Source folder: %s\n', source_folder);
fprintf('Destination folder: %s\n', destination_folder);
fprintf('Available source images: %d\n', num_source_files);
fprintf('Selected source indices: %d to %d (%d images)\n', ...
    img_list(1), img_list(end), num_input_images);
fprintf('Global output ID range: %d to %d\n', output_id_start, output_id_end);
fprintf('Expected output images: %d\n\n', total_images);

%% Generate blurred images

blur_smajram_images(source, mask_size, img_type, ...
    destination_folder, img_list, output_id_start, output_id_end, total_images, ...
    show_progress, show_visuals, progress_interval);

%% Local function

function new_img = blur_smajram_images(source, mask_size, img_type, ...
    destination, img_list, output_id_start, output_id_end, total_images, ...
    show_progress, show_visuals, progress_interval)

    % Select only the configured source images.
    im_folder = source(img_list);
    num_images = numel(im_folder);
    num_mask = numel(mask_size);
    num_outputs_per_input = num_mask + 1;
    expected_output_count = num_images * num_outputs_per_input;

    % Recheck the configuration inside the worker function.
    if expected_output_count ~= total_images || ...
            output_id_end - output_id_start + 1 ~= total_images
        error('The selected input range, output count, and global ID range do not agree.');
    end

    % Local array index is separate from the global ID used in filenames.
    new_img = strings(total_images, 1);
    local_idx = 0;
    global_id = output_id_start;

    start_time = tic;
    next_progress = progress_interval;

    if show_progress
        fprintf('\nSMAjram Blur Generation\n');
        fprintf('Input images: %d\n', num_images);
        fprintf('Blur masks: %s\n', mat2str(mask_size));
        fprintf('Outputs per input: %d\n', num_outputs_per_input);
        fprintf('Expected output images: %d\n', total_images);
        fprintf('Global ID range: %d - %d\n\n', output_id_start, output_id_end);
        fprintf('Progress:   0%%');
    end

    for i = 1:num_images
        current_file = fullfile(im_folder(i).folder, im_folder(i).name);
        img = imread(current_file);

        % Extract source filename metadata beginning with rotation or size.
        [~, source_name, ~] = fileparts(im_folder(i).name);
        metadata_start = strfind(source_name, '(A');
        if isempty(metadata_start)
            metadata_start = strfind(source_name, '(s');
        end
        if isempty(metadata_start)
            error('Unexpected source filename format: %s', im_folder(i).name);
        end
        metadata = source_name(metadata_start(1):end);

        % -------------------------------------------------------------
        % B00: Original image
        % -------------------------------------------------------------
        local_idx = local_idx + 1;
        if global_id > output_id_end
            error('Generated output ID would exceed output_id_end.');
        end

        image_id = sprintf('g%010d', global_id);
        blur_tag = '(B00)';
        new_img(local_idx) = strcat(image_id, blur_tag, metadata, img_type);
        image_path = fullfile(destination, char(new_img(local_idx)));
        if isfile(image_path)
            error('Output file already exists; stopping to avoid overwriting: %s', image_path);
        end
        imwrite(img, image_path);
        global_id = global_id + 1;

        if show_visuals
            imshowpair(img, img, 'montage');
            title('Blur: Original');
            drawnow;
        end

        % -------------------------------------------------------------
        % B11, B13, B15: Blurred images
        % -------------------------------------------------------------
        for j = 1:num_mask
            mask = fspecial('disk', mask_size(j));
            blurred_img = imfilter(img, mask);

            local_idx = local_idx + 1;
            if global_id > output_id_end
                error('Generated output ID would exceed output_id_end.');
            end

            image_id = sprintf('g%010d', global_id);
            blur_tag = sprintf('(B1%d)', mask_size(j));
            new_img(local_idx) = strcat(image_id, blur_tag, metadata, img_type);
            image_path = fullfile(destination, char(new_img(local_idx)));
            if isfile(image_path)
                error('Output file already exists; stopping to avoid overwriting: %s', image_path);
            end
            imwrite(blurred_img, image_path);
            global_id = global_id + 1;

            if show_visuals
                imshowpair(img, blurred_img, 'montage');
                title(sprintf('Blur: Disk radius %d', mask_size(j)));
                drawnow;
            end
        end

        % Display processing progress.
        if show_progress
            progress = i / num_images;
            if progress >= next_progress || i == num_images
                fprintf('\b\b\b\b%3.0f%%', progress * 100);
                next_progress = next_progress + progress_interval;
            end
        end
    end

    elapsed_time = toc(start_time);

    if local_idx ~= total_images
        error('Output count mismatch: expected %d files, generated %d names.', ...
            total_images, local_idx);
    end

    if global_id - 1 ~= output_id_end
        error('Final global output ID (%d) does not match output_id_end (%d).', ...
            global_id - 1, output_id_end);
    end

    if show_progress
        fprintf('\nBlur generation completed.\n');
        fprintf('Output images: %d\n', local_idx);
        fprintf('Global ID range: %d - %d\n', output_id_start, global_id - 1);
        fprintf('Elapsed time: %.1f seconds.\n\n', elapsed_time);
    end
end
