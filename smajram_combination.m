%% SMAjram Combination Generation (Batch-wise)
% Generates the original image and combination images by varying
% text/background intensity using image complement.
%
% Each selected input image produces 13 outputs with the default factors:
%   1 original image + 4 text factors x 3 background factors.
%
% IMPORTANT:
%   Configure img_list, output_id_start, output_id_end, and destination_folder
%   for each batch according to the SMAjram Gen Guide.

clear;
clc;

%% User Configuration

source_folder = 'RotE';
destination_folder = 'Ajram_Combination1';
img_type = '.png';

% Combination factors (preserved from the original function)
txt_factor = 0:50:150;
bg_factor = 0:20:40;

% Select source images from the sorted rotation-file list.
% Configure the source range for the intended batch using the Gen Guide.
img_list = 1:60000;

% Global output ID range for this batch.
% Global output ID range for this batch, taken from the Gen Guide.
output_id_start = 1872001;
output_id_end   = 2652000;

%
total_images = output_id_end - output_id_start + 1;

% Display options
show_progress = true;
show_visuals = false;
progress_interval = 0.01;

%% Prepare and validate input

if ~isfolder(source_folder)
    error('Source folder does not exist: %s', source_folder);
end

source = dir(fullfile(source_folder, ['*' img_type]));
source = source(~[source.isdir]);

% Explicitly sort by filename so source indices are reproducible.
if ~isempty(source)
    [~, sort_idx] = sort({source.name});
    source = source(sort_idx);
end

num_available = numel(source);

if num_available == 0
    error('No %s images were found in source folder: %s', ...
        img_type, source_folder);
end

if ~isnumeric(img_list) || isempty(img_list) || ...
        any(~isfinite(img_list)) || any(img_list ~= fix(img_list)) || ...
        any(img_list < 1) || any(img_list > num_available)
    error('img_list must contain valid integer indices between 1 and %d for the sorted source-file list.', ...
        num_available);
end

if ~isscalar(output_id_start) || ~isscalar(output_id_end) || ...
        ~isfinite(output_id_start) || ~isfinite(output_id_end) || ...
        output_id_start ~= fix(output_id_start) || ...
        output_id_end ~= fix(output_id_end) || ...
        output_id_start < 1 || output_id_end < output_id_start
    error('The output ID range must contain positive integers with end >= start.');
end

if ~isscalar(progress_interval) || progress_interval <= 0 || progress_interval > 1
    error('progress_interval must be greater than 0 and no greater than 1.');
end

num_comp = numel(txt_factor);
num_bg = numel(bg_factor);
outputs_per_input = 1 + num_comp * num_bg;
num_selected = numel(img_list);
expected_images = num_selected * outputs_per_input;

if total_images ~= expected_images
    error(['Batch configuration mismatch: %d input images x %d outputs per input = %d expected outputs, ' ...
        'but the configured ID range contains %d IDs. Check img_list and the output ID range against the Gen Guide.'], ...
        num_selected, outputs_per_input, expected_images, total_images);
end

fprintf('Source folder: %s\n', source_folder);
fprintf('Destination folder: %s\n', destination_folder);
fprintf('Available source images: %d\n', num_available);
fprintf('Selected source indices: %d to %d (%d images)\n', ...
    img_list(1), img_list(end), num_selected);
fprintf('Global output ID range: %d to %d\n', ...
    output_id_start, output_id_end);
fprintf('Expected output images: %d\n\n', total_images);

if ~isfolder(destination_folder)
    mkdir(destination_folder);
end

%% Generate combination images

combine_smajram_images(source, txt_factor, bg_factor, img_type, ...
    destination_folder, img_list, output_id_start, output_id_end, ...
    total_images, show_progress, show_visuals, progress_interval);

%% Local function

function new_img = combine_smajram_images(source, txt_factor, bg_factor, ...
    img_type, destination, img_list, output_id_start, output_id_end, ...
    total_images, show_progress, show_visuals, progress_interval)

selected_source = source(img_list);
num_images = numel(selected_source);
num_comp = numel(txt_factor);
num_bg = numel(bg_factor);
outputs_per_input = 1 + num_comp * num_bg;
expected_images = num_images * outputs_per_input;

if expected_images ~= total_images || ...
        output_id_end - output_id_start + 1 ~= total_images
    error('Internal batch validation failed: selected inputs, expected outputs, and output ID range do not agree.');
end

% Local array indexing is separate from global filename IDs.
new_img = strings(total_images, 1);
local_idx = 0;

start_time = tic;
next_progress = progress_interval;

if show_progress
    fprintf('\nSMAjram Combination Generation\n');
    fprintf('Input images: %d\n', num_images);
    fprintf('Text factors: %s\n', mat2str(txt_factor));
    fprintf('Background factors: %s\n', mat2str(bg_factor));
    fprintf('Outputs per input: %d\n', outputs_per_input);
    fprintf('Expected output images: %d\n', total_images);
    fprintf('Global ID range: %d - %d\n\n', output_id_start, output_id_end);
    fprintf('Progress:   0%%');
end

for i = 1:num_images
    source_file = selected_source(i).name;
    source_path = fullfile(selected_source(i).folder, source_file);
    img = imread(source_path);

    [~, source_name, ~] = fileparts(source_file);

    % Retain metadata beginning with rotation angle, or font-size if
    % the source filename is a non-rotated character image.
    metadata_start = strfind(source_name, '(A');
    if isempty(metadata_start)
        metadata_start = strfind(source_name, '(s');
    end
    if isempty(metadata_start)
        error('Unexpected source filename format: %s', source_file);
    end
    metadata = source_name(metadata_start(1):end);

    % Original image
    local_idx = local_idx + 1;
    output_id = output_id_start + local_idx - 1;
    image_id = sprintf('g%010d', output_id);
    combination_tag = '(O00000)';
    new_img(local_idx) = strcat(image_id, combination_tag, metadata, img_type);
    image_path = fullfile(destination, new_img(local_idx));
    if isfile(image_path)
        error('Output file already exists; stopping to avoid overwriting: %s', image_path);
    end
    imwrite(img, image_path);

    if show_visuals
        imshowpair(img, img, 'montage');
        title('Combination: Original');
        drawnow;
    end

    % Text/background combination images
    for y = 1:num_comp
        for z = 1:num_bg
            combined_img = 0.9 * imcomplement(img) ...
                + txt_factor(y) - bg_factor(z);

            local_idx = local_idx + 1;
            output_id = output_id_start + local_idx - 1;
            image_id = sprintf('g%010d', output_id);
            combination_tag = sprintf('(T%02dB%02d)', txt_factor(y), bg_factor(z));
            new_img(local_idx) = strcat(image_id, combination_tag, metadata, img_type);
            image_path = fullfile(destination, new_img(local_idx));
            if isfile(image_path)
                error('Output file already exists; stopping to avoid overwriting: %s', image_path);
            end
            imwrite(combined_img, image_path);

            if show_visuals
                imshowpair(img, combined_img, 'montage');
                title(sprintf('Combination: T%d, B%d', txt_factor(y), bg_factor(z)));
                drawnow;
            end
        end
    end

    if show_progress
        progress = i / num_images;
        if progress >= next_progress || i == num_images
            fprintf('\b\b\b\b%3.0f%%', progress * 100);
            next_progress = next_progress + progress_interval;
        end
    end
end

if local_idx ~= total_images
    error('Generation ended with %d outputs; expected %d.', local_idx, total_images);
end
if output_id_start + local_idx - 1 ~= output_id_end
    error('Final output ID does not match output_id_end. Expected %d, obtained %d.', ...
        output_id_end, output_id_start + local_idx - 1);
end

if show_progress
    elapsed_time = toc(start_time);
    fprintf('\nCombination generation completed.\n');
    fprintf('Output images: %d\n', local_idx);
    fprintf('Global ID range: %d - %d\n', output_id_start, output_id_end);
    fprintf('Elapsed time: %.1f seconds.\n\n', elapsed_time);
end

end
