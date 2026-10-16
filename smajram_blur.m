%% SMAjram Blur Generation
% Generates the original image and blurred versions using disk filters.
%
% Input:
%   AjramRot
%
% Output:
%   Ajram_Blur
%
% Each input image produces:
%   B0 = Original image
%   B1 = Disk filter, radius 1
%   B3 = Disk filter, radius 3
%   B5 = Disk filter, radius 5

clear;
clc;

%% User Configuration

source_folder = 'AjramRot';
destination_folder = 'Ajram_Blur';

img_type = '.png';

% Disk-filter radii used for blur generation
mask_size = [1 3 5];
% Continue global image IDs after the input images.
output_id_start = 301 % last folder image # + 1;

% Display options
show_progress = true;    % Show processing progress
show_visuals = false;    % Display generated images during processing
progress_interval = 0.01; % Progress update interval (1% = 0.01)

%% Prepare input and output

source = dir(fullfile(source_folder, ['*' img_type]));

num_img = numel(source);

if num_img == 0
    error('No %s images were found in the source folder: %s', ...
        img_type, source_folder);
end

img_list = 1:num_img;

if ~exist(destination_folder, 'dir')
    mkdir(destination_folder);
end

num_mask = numel(mask_size);
num_op_images = num_img * (num_mask + 1);

%% Generate blurred images

blur_smajram_images(source, mask_size, img_type, ...
    destination_folder, img_list, output_id_start, ...
    show_progress, show_visuals, progress_interval);


%% Local function

function new_img = blur_smajram_images(source, mask_size, img_type, ...
    destination, img_list, output_id_start, ...
    show_progress, show_visuals, progress_interval)

im_folder = source(img_list);
file_path = im_folder(1).folder;
filen = {im_folder.name}';

num_images = numel(img_list);
num_mask = numel(mask_size);
num_op_images = num_images * (num_mask + 1);

new_img = strings(num_op_images, 1);
iter = output_id_start - 1;

% Start progress timer
start_time = tic;
next_progress = progress_interval;

if show_progress
    fprintf('\nSMAjram Blur\n');
    fprintf('Input images: %d\n', num_images);
    fprintf('Blur masks: %s\n', mat2str(mask_size));
    fprintf('Expected output images: %d\n\n', num_op_images);
    fprintf('Progress:   0%%');
end

for i = 1:num_images

    img = imread(fullfile(file_path, filen{i}));

    % Extract the source filename components used in the output name.
    [~, source_name, ~] = fileparts(filen{i});

    % Source format example:
    % g00072001(A-45)(s100){Adobe Arabic}_Alif Iso
    %
    % Remove the original global ID and retain everything beginning
    % with the augmentation/font-size metadata.
    metadata_start = strfind(source_name, '(A');

    if isempty(metadata_start)
        metadata_start = strfind(source_name, '(s');
    end

    if isempty(metadata_start)
        error('Unexpected source filename format: %s', filen{i});
    end

    metadata = source_name(metadata_start(1):end);

    % -------------------------------------------------------------
    % B0: Original image
    % -------------------------------------------------------------

    iter = iter + 1;

    output_id = iter;
    image_id = sprintf('g%08d', output_id);
    blur_tag = '(B00)';

    new_img(iter) = strcat( ...
        image_id, blur_tag, metadata, img_type);

    image_path = fullfile(destination, new_img(iter));
    imwrite(img, image_path);

    if show_visuals
        imshowpair(img, img, 'montage');
        title('Blur: Original');
        drawnow;
    end

    % -------------------------------------------------------------
    % B1, B3, B5: Blurred images
    % -------------------------------------------------------------

    for j = 1:num_mask

        mask = fspecial('disk', mask_size(j));
        blurred_img = imfilter(img, mask);

        iter = iter + 1;

        output_id = iter;
        image_id = sprintf('g%08d', output_id);
        blur_tag = sprintf('(B1%d)', mask_size(j));

        new_img(iter) = strcat( ...
            image_id, blur_tag, metadata, img_type);

        image_path = fullfile(destination, new_img(iter));
        imwrite(blurred_img, image_path);

        if show_visuals
            imshowpair(img, blurred_img, 'montage');
            title(sprintf('Blur: Disk radius %d', mask_size(j)));
            drawnow;
        end
    end

    % -------------------------------------------------------------
    % Display processing progress
    % -------------------------------------------------------------

    if show_progress
        progress = i / num_images;

        if progress >= next_progress || i == num_images
            elapsed_time = toc(start_time);

            fprintf('\b\b\b\b%3.0f%%', progress * 100);

            next_progress = next_progress + progress_interval;
        end
    end
end

if show_progress
    fprintf('\nBlur generation completed.\n');
    fprintf('Output images: %d\n', num_op_images);
    fprintf('Elapsed time: %.1f seconds.\n\n', elapsed_time);
end

end
