%% Initialization
clear;
close all;
addpath('utils');
addpath('solver');

%% Parameters
% controls
file_type = '.png';
use_python_matching = true; % whether to use the python matching algorithm
interpreter_path = 'C:/Users/hw/.conda/envs/Matlab/python.exe'; % the path of the python interpreter
do_register = true;
do_match = true;
if use_python_matching
    pyenv('Version', interpreter_path);
end

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
    'debug_register', false, ... % whether to show the registered images
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
    'debug_matchinput', false, ...
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
    if ~use_python_matching
        disp('Matching input fingerprints...');
        [result, time_match] = match_input(config_1, config_2);
        disp(['Fingerprint matching finished in ' num2str(time_match) 's.']);
        disp(['Result: ', result]);
    else
        tic;
        input_files = dir([config_2.input_image_folder '*' config_2.file_type]);
        for i = 1 : length(input_files)
            image = imread([config_2.input_image_folder input_files(i).name]);
            key = input_files(i).name(1 : end - length(config_2.file_type));
            minutiae = extract_input_minu(image, config_1, key);
        end
        mat2txt();
        if count(py.sys.path, '') == 0
            insert(py.sys.path, int32(0), '');
        end
        py.importlib.import_module('match_python');
        py.match_python.matching();
        time_match = toc;
        disp(['Fingerprint matching finished in ' num2str(time_match) 's.']);
        % status = system('python match_python.py');
    end
end

close all;
