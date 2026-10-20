%% SMAjram Outline Augmentation (Batch-wise)
% Applies outline/color transformations to selected images from the rotation set.
%
% Each input image produces:
%   1 original image
%   18 outline/color combinations
%   18 complementary images
% Total: 37 output images per input image.
%
% The original transformation algorithm and filename metadata are preserved.

clear;
clc;

%% User configuration

source_folder = 'RotE';
destination_folder = 'Ajram_Outline1';
img_type = '.png';

% Select source-image positions from the sorted source-file list.
% Change these values for each batch using the SMAjram Gen Guide.
img_list = 1:12000;
% 
% Global output ID range for this batch (from the Gen Guide).
output_id_start = 6552001;
output_id_end   = 6996000;

total_images = output_id_end - output_id_start + 1;

% Outline parameters (preserved from the original function)
txt_colr = [50 250];
outline_colr = [100 150 200];
bkg_colr = [80 160 240];

% Display and progress options
show_progress = true;
show_visuals = false;
progress_interval = 0.01;

%% Validate configuration and prepare source files

if ~isscalar(progress_interval) || ~isnumeric(progress_interval) || ...
        ~isfinite(progress_interval) || progress_interval <= 0 || progress_interval > 1
    error('progress_interval must be a numeric scalar in the interval (0, 1].');
end

if ~isfolder(source_folder)
    error('Source folder does not exist: %s', source_folder);
end

source = dir(fullfile(source_folder, ['*' img_type]));
source = source(~[source.isdir]);
% MATLAB dir returns the source-file list in name-sorted order.
num_available = numel(source);

if num_available == 0
    error('No %s images were found in the source folder: %s', img_type, source_folder);
end

if isempty(img_list) || ~isnumeric(img_list) || ~isvector(img_list) || ...
        any(~isfinite(img_list)) || any(img_list ~= fix(img_list)) || ...
        any(img_list < 1) || any(img_list > num_available)
    error('img_list must contain valid integer indices between 1 and %d for the sorted source-file list.', num_available);
end

if numel(unique(img_list)) ~= numel(img_list)
    error('img_list contains duplicate source indices. Each source index must be selected only once per batch.');
end

if ~isscalar(output_id_start) || ~isscalar(output_id_end) || ...
        ~isnumeric(output_id_start) || ~isnumeric(output_id_end) || ...
        ~isfinite(output_id_start) || ~isfinite(output_id_end) || ...
        output_id_start < 1 || output_id_end < output_id_start || ...
        output_id_start ~= fix(output_id_start) || output_id_end ~= fix(output_id_end)
    error('The output ID range must contain positive integers with end >= start.');
end

if isempty(txt_colr) || isempty(outline_colr) || isempty(bkg_colr) || ...
        any([txt_colr(:); outline_colr(:); bkg_colr(:)] < 0) || ...
        any([txt_colr(:); outline_colr(:); bkg_colr(:)] > 255) || ...
        any([txt_colr(:); outline_colr(:); bkg_colr(:)] ~= fix([txt_colr(:); outline_colr(:); bkg_colr(:)]))
    error('Colour parameters must be integer values between 0 and 255.');
end

num_txt_colr = numel(txt_colr);
num_outline_colr = numel(outline_colr);
num_bkg_colr = numel(bkg_colr);
num_combinations = num_txt_colr * num_outline_colr * num_bkg_colr;
num_outputs_per_image = 1 + 2 * num_combinations;
num_selected = numel(img_list);

% Calculate expected outputs independently from the configured ID range.
expected_images = num_selected * num_outputs_per_image;
configured_images = output_id_end - output_id_start + 1;

fprintf('Source folder: %s\n', source_folder);
fprintf('Destination folder: %s\n', destination_folder);
fprintf('Available source images: %d\n', num_available);
fprintf('Selected source indices: %d to %d (%d images)\n', ...
    img_list(1), img_list(end), num_selected);
fprintf('Global output ID range: %d to %d\n', output_id_start, output_id_end);
fprintf('Expected output images: %d\n\n', expected_images);

if configured_images ~= expected_images
    error(['Batch configuration mismatch: %d input images x %d outputs per input = %d expected outputs, ' ...
        'but the configured ID range contains %d IDs. Check img_list and the output ID range against the Gen Guide.'], ...
        num_selected, num_outputs_per_image, expected_images, configured_images);
end

% Use the expected count only after configuration validation succeeds.
total_images = expected_images;

if output_id_end > 9999999999
    error('output_id_end exceeds the 10-digit global ID naming capacity.');
end

if ~isfolder(destination_folder)
    mkdir(destination_folder);
end

% Existing filenames are checked individually before each output is written.
% This permits successive non-overlapping batches to share one destination folder.

%% Generate selected outline batches

outline_smajram_images(source, img_list, destination_folder, ...
    output_id_start, output_id_end, txt_colr, outline_colr, bkg_colr, ...
    show_progress, show_visuals, progress_interval);

%% Local function
function outline_smajram_images(source, img_list, destination_folder, ...
    output_id_start, output_id_end, txt_colr, outline_colr, bkg_colr, ...
    show_progress, show_visuals, progress_interval)

    num_images = numel(img_list);
    num_combinations = numel(txt_colr) * numel(outline_colr) * numel(bkg_colr);
    num_outputs_per_image = 1 + 2 * num_combinations;
    total_images = num_images * num_outputs_per_image;

    % Local array/output counter is independent of the global filename ID.
    local_output_count = 0;
    global_output_id = output_id_start - 1;

    if show_progress
        fprintf('SMAjram Outline Generation\n');
        fprintf('Input images: %d\n', num_images);
        fprintf('Combinations per input: %d\n', num_combinations);
        fprintf('Outputs per input: %d\n', num_outputs_per_image);
        fprintf('Expected output images: %d\n', total_images);
        fprintf('Global ID range: %d - %d\n\n', output_id_start, output_id_end);
        fprintf('Progress:   0%%');
    end

    start_time = tic;
    next_progress = progress_interval;

    for im = 1:num_images
        source_index = img_list(im);
        file_name = source(source_index).name;
        file_path = fullfile(source(source_index).folder, file_name);
        img = imread(file_path);

        % Background value from the original image.
        bkg = img(1,1);

        % Retain original metadata beginning with rotation or size field.
        metadata = extract_metadata(file_name);

        %% Original image
        global_output_id = global_output_id + 1;
        local_output_count = local_output_count + 1;
        output_name = sprintf('g%010d(O)%s', global_output_id, metadata);
        write_output(img, destination_folder, output_name);

        %% Outline/color combinations and their complements
        for tc = 1:numel(txt_colr)
            for oc = 1:numel(outline_colr)
                for bc = 1:numel(bkg_colr)
                    % Preserve the original outline-generation algorithm.
                    R = imsplit(img);
                    brd = uint8(imgradient(imgradient(imgradient(imgradient(imgradient(R))))));

                    brd(brd > bkg) = 1;
                    R(R > bkg) = 2;
                    RB = R + brd;
                    RB(RB == 0) = bkg_colr(bc);
                    RB(RB == 1) = outline_colr(oc);
                    RB(RB == 3) = txt_colr(tc);
                    img2 = cat(3, RB, RB, RB);

                    % Outline image
                    global_output_id = global_output_id + 1;
                    local_output_count = local_output_count + 1;
                    output_name = sprintf('g%010d(%03d,%03d,%03d)%s', ...
                        global_output_id, txt_colr(tc), outline_colr(oc), ...
                        bkg_colr(bc), metadata);
                    write_output(img2, destination_folder, output_name);

                    % Complementary image
                    img3 = imcomplement(img2);
                    global_output_id = global_output_id + 1;
                    local_output_count = local_output_count + 1;
                    output_name = sprintf('g%010d(%03d,%03d,%03d)%s', ...
                        global_output_id, 255 - txt_colr(tc), ...
                        255 - outline_colr(oc), 255 - bkg_colr(bc), metadata);
                    write_output(img3, destination_folder, output_name);

                    if show_visuals
                        figure(1);
                        clf;
                        subplot(2,2,1); imshow(img); title('Original');
                        subplot(2,2,2); imshow(img2);
                        title(sprintf('Outline: (%03d,%03d,%03d)', ...
                            txt_colr(tc), outline_colr(oc), bkg_colr(bc)));
                        subplot(2,2,3); imshow(img3);
                        title(sprintf('Complement: (%03d,%03d,%03d)', ...
                            255-txt_colr(tc), 255-outline_colr(oc), 255-bkg_colr(bc)));
                        subplot(2,2,4); imshowpair(img, img2, 'montage');
                        title('Original / Outline');
                        sgtitle(sprintf('Global ID: %010d', global_output_id));
                        drawnow;
                    end
                end
            end
        end

        if show_progress
            progress = im / num_images;
            if progress >= next_progress || im == num_images
                fprintf('\b\b\b\b%3.0f%%', progress * 100);
                next_progress = next_progress + progress_interval;
            end
        end
    end

    elapsed_time = toc(start_time);
    if local_output_count ~= total_images || global_output_id ~= output_id_end
        error('Internal batch count mismatch: generated %d images; expected %d. Final global ID: %d; expected %d.', ...
            local_output_count, total_images, global_output_id, output_id_end);
    end

    if show_progress
        fprintf('\nOutline generation completed.\n');
        fprintf('Output images: %d\n', local_output_count);
        fprintf('Global ID range: %d - %d\n', output_id_start, global_output_id);
        fprintf('Elapsed time: %.1f seconds.\n\n', elapsed_time);
    end
end

function write_output(img, destination_folder, output_name)
    image_path = fullfile(destination_folder, output_name);
    if isfile(image_path)
        error('Output file already exists; refusing to overwrite: %s', image_path);
    end
    imwrite(img, image_path);
end

function metadata = extract_metadata(file_name)
    % Preserve metadata beginning with (A or (s, including the character label.
    start_idx = strfind(file_name, '(A');
    if isempty(start_idx)
        start_idx = strfind(file_name, '(s');
    end
    if isempty(start_idx)
        error('Required rotation/size metadata could not be found in filename: %s', file_name);
    end
    metadata = file_name(start_idx(1):end);
end
