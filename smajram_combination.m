%% SMAjram Combination Generation
% Generates the original image and combination images by varying
% text/background intensity using image complement.
%
% Input:
%   AjramRot
%
% Output:
%   Ajram_Combination
%
% Combination parameters:
%   txt_factor = 0:50:150
%   bg_factor   = 0:20:40

clear;  clc;

%% User Configuration

source_folder = 'nineRot' %'AjramRot';
destination_folder = 'nineCombination' %'Ajram_Combination';

img_type = '.png';

% Combination factors
txt_factor = 0:50:150;
bg_factor = 0:20:40;

% Continue global image IDs after the input images.
output_id_start = 1301 % last folder image # + 1;

% Display options
show_progress = true;     % Show processing progress
show_visuals = false;     % Display generated images during processing
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

num_comp = numel(txt_factor);
num_bg = numel(bg_factor);

% One original image plus all combinations
num_op_images = num_img * (1 + num_comp * num_bg);

%% Generate combination images

combine_smajram_images(source, txt_factor, bg_factor, img_type, ...
    destination_folder, img_list, output_id_start, ...
    show_progress, show_visuals, progress_interval);


%% Local function

function new_img = combine_smajram_images(source, txt_factor, bg_factor, ...
    img_type, destination, img_list, output_id_start, ...
    show_progress, show_visuals, progress_interval)

im_folder = source(img_list);
file_path = im_folder(1).folder;
filen = {im_folder.name}';

num_images = numel(img_list);
num_comp = numel(txt_factor);
num_bg = numel(bg_factor);
num_op_images = num_images * (1 + num_comp * num_bg);

new_img = strings(num_op_images, 1);
iter = output_id_start - 1;

% Start progress timer
start_time = tic;
next_progress = progress_interval;

if show_progress
    fprintf('\nSMAjram Combination\n');
    fprintf('Input images: %d\n', num_images);
    fprintf('Combination factors: %d\n', num_comp);
    fprintf('Background factors: %d\n', num_bg);
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
    % Retain everything beginning with the augmentation/font-size
    % metadata.
    metadata_start = strfind(source_name, '(A');

    if isempty(metadata_start)
        metadata_start = strfind(source_name, '(s');
    end

    if isempty(metadata_start)
        error('Unexpected source filename format: %s', filen{i});
    end

    metadata = source_name(metadata_start(1):end);

    % -------------------------------------------------------------
    % Original image
    % -------------------------------------------------------------

    iter = iter + 1;

    output_id = iter ;
    image_id = sprintf('g%08d', output_id);
    combination_tag = '(O00000)';

    new_img(iter) = strcat( ...
        image_id, combination_tag, metadata, img_type);

    image_path = fullfile(destination, new_img(iter));
    imwrite(img, image_path);

    if show_visuals
        imshowpair(img, img, 'montage');
        title('Combination: Original');
        drawnow;
    end

    % -------------------------------------------------------------
    % Combination images
    % -------------------------------------------------------------

    for y = 1:num_comp
        for z = 1:num_bg

            combined_img = 0.9 * imcomplement(img) ...
                + txt_factor(y) - bg_factor(z);

            iter = iter + 1;

            output_id =  iter;
            image_id = sprintf('g%08d', output_id);

            combination_tag = sprintf('(T%dB%d)', ...
                txt_factor(y), bg_factor(z));

            new_img(iter) = strcat( ...
                image_id, combination_tag, metadata, img_type);

            image_path = fullfile(destination, new_img(iter));
            imwrite(combined_img, image_path);

            if show_visuals
                imshowpair(img, combined_img, 'montage');
                title(sprintf('Combination: T%d, B%d', ...
                    txt_factor(y), bg_factor(z)));
                drawnow;
            end
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
    fprintf('\nCombination generation completed.\n');
    fprintf('Output images: %d\n', num_op_images);
    fprintf('Elapsed time: %.1f seconds.\n\n', elapsed_time);
end

end