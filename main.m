%% Initialization
clear;
close all;
addpath('utils');
addpath('solver');

%% Parameters
% controls
file_type = '.png';
do_register = false;
do_match = true;

% config_1: the configuration for minutiae extraction
config_1 = struct(...
    'block_size', 8, 'extended_size', 32, 'threshold', 0, ...
    'd', 1, 'mask', 'uniform', ...
    'smooth_filter_size', 3, 'smooth_filter_sigma', 1, ...
    'gabor_filter_size', 17, 'gabor_filter_sigma', 4, ... % above are the parameters for image enhancement
    'small_object_size', 15, 'binarize_sensitivity', 0.5, ...
    'prune_length', 6, 'small_branch_size', 5, ...
    'bridge_length', 0, 'bridge_d', 0, ...
    'remove_margin_length', 16, ... % above are the parameters for minutiae extraction
    'regist_folder', 'image/regist/', ... % the folder to save the enhanced images
    'input_folder', 'image/input/', ... % the folder to save the input images
    'debug_enhance', false, ... % whether to show the enhanced images
    'debug_register', true, ... % whether to show the registered images
    'debug_input', false, ... % whether to show the input images
    'file_type', file_type ... % the type of the image files
);

% config_2: the configuration for matching
config_2 = struct( ...
    'dist_threshold', 30, ...
    'angle_threshold', 30, ... % thresholds for minutiae matching
    'translation_penalty', 0, ...
    'rotation_penalty', 0, ...
    'unmatched_penalty', 0.1, ... % penalties for matching failure
    'regist_image_folder', 'image/regist/', ...
    'input_image_folder', 'image/input/', ...
    'regist_minu_folder', 'result/register/', ... % paths
    'input_minu_folder', 'result/input/', ...
    'debug_match', false, ...
    'debug_matchinput', true, ...
    'debug_matchinput_showtopN', 5, ...
    'debug_display_figure', false, ... % debug flags
    'file_type', file_type ...
);

%% Extract the minutiae of the registered images
if do_register
    disp('Extracting minutiae of the registered images...');
    tic;
    extract_regist_minu(config_1);
    time_regist = toc; 
    disp(['Minutiae extraction of the registered images finished in ' num2str(time_regist) 's.']);
end

close all;

%% Matching input fingerprints
if do_match
    disp('Matching input fingerprints...');
    result = match_input(config_1, config_2);
    disp(['Fingerprint matching finished.']);
    disp(['Result: ', result]);
end

close all;
