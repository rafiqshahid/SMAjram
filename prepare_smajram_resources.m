%% prepare_smajram_resources.m
% Creates the character and font resource files used by the SMAjram
% synthetic Shahmukhi character-image generation software.
%
% Required input file:
%   Shah_AjramnFont_Updated.xlsx
%
% Generated resource files:
%   shah_ajram240.mat
%   font_list50.mat
%   shah_ajram_Tab.xlsx

%% Read character specification

char_Array = readcell('Shah_AjramnFont_Updated_clean.xlsx', 'Sheet', 'ShahAjram');
char_Array = char_Array(2:end, :);   % Remove column headers

shah_Chars = char_Array(:, 1);
labels = string(char_Array(:, 2));
eLabels = string(char_Array(:, 3));
alpha_codes = double(char(shah_Chars));
shah_ajram = char(alpha_codes);

char_code_labels = [shah_ajram labels eLabels alpha_codes];

ajram240 = table(shah_ajram, labels, eLabels, alpha_codes);

% Human-readable tabular reference of the character specification.
writetable(ajram240, 'shah_ajram_Tab.xlsx');

% Save character resources used by the image-generation software.
save('shah_ajram240.mat', ...
    'ajram240', 'shah_Chars', 'shah_ajram', 'alpha_codes', ...
    'labels', 'eLabels', 'char_code_labels', '-v7.3');

%% Read font specification

font_list = readcell('Shah_AjramnFont_Updated_clean.xlsx', 'Sheet', 'Ajram_Fonts');
font_list = font_list(2:51, 1);   % Select first column and remove header

% Save the font list used by the image-generation software.
save('font_list50.mat', 'font_list', '-v7.3');
