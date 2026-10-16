%% generate_smajram_characters.m
% Generates base synthetic Shahmukhi character images for SMAjram.
%
% Required resource files:
%   font_list50.mat
%   shah_ajram240.mat
%
% The default configuration below reflects the configuration used for
% generating the base character images in the original research workflow.
%
% The generated images are saved as PNG files.

%% User Configuration

% Output folder
main_dir = 'nineMaYour Folder' %'AjramMainP0';

% Check if the folder does not exist
if ~isfolder(main_dir)
    mkdir(main_dir);
    fprintf('Folder "%s" created successfully.\n', main_dir);
else
    fprintf('Folder "%s" already exists.\n', main_dir);
end

% Rendering canvas size
canvas_size = 400;

% Final output image size
output_size = [100 100];

% Font sizes
font_sizes = 50:10:100;

% Number of copies of each character/font/size combination
num_copies = 1;

% Character and background colors
text_color = 'white';  background_color = 'black';

% Load character and font resources

load font_list50.mat
load shah_ajram240.mat

% The resource file stores the Shahmukhi characters in 'shah_ajram'.
% Convert them to a cell array for character-wise access.
alpha = cellstr(shah_ajram);
data_labels = eLabels;  % or labels for Punjabi labels

% Prepare rendering canvas

img_ext = '.png';

% Convert the background color to its numeric image value.
bg_color = 255 * validatecolor(background_color);

W = canvas_size;
H = W; % canvas_size;

% Create the background image.
background_image = bg_color(1) * ones(H, W, 'uint8');

% Center position for character rendering.
x = 0.5; y = 0.5;
text_position = [round(x*W) round(y*H)];

% Calculate generation parameters

num_alpha = length(alpha);
num_fonts = numel(font_list);
num_fsize = numel(font_sizes);

num_images = num_alpha * num_fonts * num_fsize * num_copies

% Generate base character images

iter = 0;

for a = 1:num_alpha
    harf = alpha{a};
    for f = 1:num_fonts
        for fs = 1:num_fsize
            iter = iter + 1;

            % Display the background canvas.
            imshow(background_image, []);

            % Render the Shahmukhi character.
            text(text_position(1), text_position(2), harf, ...
                'FontSize', font_sizes(fs), ...
                'Color', text_color, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment','middle',...
                'FontWeight', 'normal', ...
                'FontName', font_list{f});

            % Generate a unique image identifier.
            image_id = sprintf('g%0.8d', iter);

            % Retain the original rendering workflow.
            title(image_id, ...
                'FontSize', 15, ...
                'FontWeight', 'bold', ...
                'FontName', 'Times');

            % Capture the rendered axes.
           
            frame = getframe(gca);
            image = frame.cdata;

            % Resize to the specified dataset output size.
            image_resized = imresize(image, output_size);

            % Construct the output filename.
            image_name = strcat( ...
                image_id, ...
                sprintf('(s%d)', font_sizes(fs)), ...
                sprintf('{%s}_%s', font_list{f}, data_labels(a)), ...
                img_ext);

            image_path = fullfile(main_dir, image_name);

            % Save the generated character image.
            imwrite(image_resized, image_path);

        end
    end
end
