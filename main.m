%% Initialization
clear;
close all;
addpath('utils');
addpath('solver');

%% Parameters
% Enhance config_1
config_1 = struct(...
    'block_size', 8, ...
    'extended_size', 16, ...
    'threshold', 0, ...
    'd', 1, ...
    'mask', 'uniform', ...
    'smooth_filter_size', 3, ...
    'smooth_filter_sigma', 1, ...
    'gabor_filter_size', 11, ...
    'gabor_filter_sigma', 3, ...
    'small_object_size', 15, ...
    'binarize_sensitivity', 0.5, ...
    'prune_length', 15, ...
    'small_branch_size', 10, ...
    'bridge_length', 10, ...
    'bridge_d', 1, ...
    'remove_margin_length', 16, ...
    'debug_enhance', false, ...
    'debug_register', false, ...
    'debug_input', false ...
);

config_2 = struct( ...
    'debug_match', false, ...
    'debug_matchinput', true, ...
    'debug_ninput', 5, ...
    'debug_display_figure', false ...
);

registered = true;

% Register all fingerprint images in 'image/regist'
if ~registered
    reg_dir = 'image/regist';
    image_files = dir(fullfile(reg_dir, '*.bmp'));
    for i = 1:length(image_files)
        % images are named as '1_a.bmp', ...
        % get the corresponding letter, such as 'a'
        if image_files(i).name(3:7) == 'space'
            idx = '9_space';
        else
            idx = image_files(i).name(1:3);
        end
        % register the image
        register(idx, config_1);
    end
    disp('Register finished.');
end

%% Get the minutiae of all input images
input_dir = 'image/input';
image_files = dir(fullfile(input_dir, '*.bmp'));
for i = 1:length(image_files)
    % images are named as '1.bmp', ...
    % get the corresponding letter, such as 'a'
    if image_files(i).name(1:2) == '10'
        idx = '10';
    else
        idx = image_files(i).name(1);
    end
    % get the minutiae of the image
    get_minu_input(idx, config_1);
    disp(['Matching ' idx '...']);
    % match the image
    if 1
        tic;
        letter = match_input(idx, config_2);
        time_match = toc;
        disp([num2str(idx) ' -> ' letter ' in ' num2str(time_match) 's.']);
    end
end

