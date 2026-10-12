%% SMAjram Outline Augmentation
% Applies outline/color transformations to images from the rotation set.
%
% Input:
%   AjramRot
%
% Output:
%   Ajram_Outline
%
% Each input image produces:
%   1 original image
%   18 outline/color combinations
%   18 complementary images
%
% Total:
%   37 output images per input image.
%
% The transformation follows the original SMAjram
% outline-generation algorithm.
%
% The global output ID is manually specified because Outline
% follows Combination in the overall SMAjram numbering sequence,
% although its input remains AjramRot.

%% User configuration

source_folder = 'nineRot' %'AjramRot';
destination_folder = 'nineOutline' %'Ajram_Outline';

img_type = '.png';

% Global ID of the first Outline output image.
% Set manually according to the overall SMAjram numbering sequence.
output_id_start = 4451;

% Outline parameters
txt_colr = [50 250];
outline_colr = [100 150 200];
bkg_colr = [80 160 240];

% Display and progress options
show_progress = true;
show_visuals = false;
progress_interval = 0.01;


%% Prepare source and destination folders

if ~exist(destination_folder, 'dir')
    mkdir(destination_folder);
end

source = dir(fullfile(source_folder, ['*' img_type]));

num_images = numel(source);

if num_images == 0
    error('No %s images were found in the source folder: %s', ...
        img_type, source_folder);
end


%% Start outline generation

outline_smajram_images( ...
    source, ...
    destination_folder, ...
    img_type, ...11
    txt_colr, ...
    outline_colr, ...
    bkg_colr, ...
    output_id_start, ...
    show_progress, ...
    show_visuals, ...
    progress_interval);


%% Local function

function outline_smajram_images( ...
    source, destination_folder, img_type, ...
    txt_colr, outline_colr, bkg_colr, ...
    output_id_start, show_progress, show_visuals, progress_interval)

    num_images = numel(source);

    % Start one count before the first requested global ID.
    iter = output_id_start - 1;

    % Number of parameter options
    num_txt_colr = numel(txt_colr);
    num_outline_colr = numel(outline_colr);
    num_bkg_colr = numel(bkg_colr);

    % Each input produces:
    %   1 original
    %   + 1 normal image for each combination
    %   + 1 complement for each combination
    num_combinations = ...
        num_txt_colr * num_outline_colr * num_bkg_colr;

    num_outputs_per_image = 1 + 2 * num_combinations;

    num_op_images = num_images * num_outputs_per_image;


    %% Progress initialization

    if show_progress
        fprintf('Outline generation started.\n');
        fprintf('Input images: %d\n', num_images);
        fprintf('Combinations per input: %d\n', num_combinations);
        fprintf('Expected output images: %d\n', num_op_images);
        fprintf('Starting global ID: %d\n\n', output_id_start);

        fprintf('Progress:   0%%');

        next_progress = progress_interval;
    end

    start_time = tic;


    %% Process images

    for im = 1:num_images

        file_name = source(im).name;
        file_path = fullfile(source(im).folder, file_name);

        img = imread(file_path);

        % Background value from the original image.
        bkg = img(1,1);


        %% Original image
        % No complement is generated for the original image.

        iter = iter + 1;

        output_name = sprintf( ...
            'g%08d(O)%s', ...
            iter, ...
            extract_metadata(file_name));

        image_path = fullfile(destination_folder, output_name);

        imwrite(img, image_path);


        %% Outline/color combinations

        for tc = 1:num_txt_colr

            for oc = 1:num_outline_colr

                for bc = 1:num_bkg_colr

                    %% Generate outline image

                    % Preserve the original outline-generation algorithm.

                    R = imsplit(img);

                    brd = uint8( ...
                        imgradient( ...
                        imgradient( ...
                        imgradient( ...
                        imgradient( ...
                        imgradient(R))))));

                    brd(brd > bkg) = 1;
                    R(R > bkg) = 2;

                    RB = R + brd;

                    RB(RB == 0) = bkg_colr(bc);
                    RB(RB == 1) = outline_colr(oc);
                    RB(RB == 3) = txt_colr(tc);

                    img2 = cat(3, RB, RB, RB);


                    %% Save outline image

                    iter = iter + 1;

                    output_name = sprintf( ...
                        'g%08d(%03d,%03d,%03d)%s', ...
                        iter, ...
                        txt_colr(tc), ...
                        outline_colr(oc), ...
                        bkg_colr(bc), ...
                        extract_metadata(file_name));

                    image_path = fullfile(destination_folder, output_name);

                    imwrite(img2, image_path);


                    %% Generate and save complement

                    img3 = imcomplement(img2);

                    iter = iter + 1;

                    output_name = sprintf( ...
                        'g%08d(%03d,%03d,%03d)%s', ...
                        iter, ...
                        255 - txt_colr(tc), ...
                        255 - outline_colr(oc), ...
                        255 - bkg_colr(bc), ...
                        extract_metadata(file_name));

                    image_path = fullfile(destination_folder, output_name);

                    imwrite(img3, image_path);


                    %% Optional troubleshooting visualization

                    if show_visuals

                        figure(1);
                        clf;

                        subplot(2,2,1);
                        imshow(img);
                        title('Original');

                        subplot(2,2,2);
                        imshow(img2);
                        title(sprintf( ...
                            'Outline: (%03d,%03d,%03d)', ...
                            txt_colr(tc), ...
                            outline_colr(oc), ...
                            bkg_colr(bc)));

                        subplot(2,2,3);
                        imshow(img3);
                        title(sprintf( ...
                            'Complement: (%03d,%03d,%03d)', ...
                            255 - txt_colr(tc), ...
                            255 - outline_colr(oc), ...
                            255 - bkg_colr(bc)));

                        subplot(2,2,4);
                        imshowpair(img, img2, 'montage');
                        title('Original / Outline');

                        sgtitle(sprintf( ...
                            'Global ID: %08d', iter));

                        drawnow;

                    end

                end
            end
        end


        %% Progress display

        if show_progress

            progress = im / num_images;

            if progress >= next_progress || im == num_images

                fprintf('\b\b\b\b%3.0f%%', progress * 100);

                next_progress = next_progress + progress_interval;

            end

        end

    end


    %% Completion message

    if show_progress

        elapsed_time = toc(start_time);

        fprintf('\nOutline generation completed.\n');
        fprintf('Output images: %d\n', num_op_images);
        fprintf('Global ID range: %d - %d\n', ...
            output_id_start, iter);
        fprintf('Elapsed time: %.1f seconds.\n\n', elapsed_time);

    end

end


%% Extract metadata from the input filename

function metadata = extract_metadata(file_name)

    % Expected input filename examples:
    %
    % g00072001(A-45)(s100){Bahij Janna Bold}_Alif Iso.png
    % g00000012(s100){Bahij Janna Bold}_Alif Iso.png
    %
    % The metadata beginning with (A or (s is retained,
    % including the original .png extension.

    start_idx = strfind(file_name, '(A');

    if isempty(start_idx)
        start_idx = strfind(file_name, '(s');
    end

    if isempty(start_idx)
        error( ...
            'Required rotation/size metadata could not be found in filename: %s', ...
            file_name);
    end

    metadata = file_name(start_idx(1):end);

end