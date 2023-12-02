%% Function to register fingerprint images
function register(image_idx, config)

%% Read image
% image_idx \in {a, b, ..., z, space}
% read 'image/regist/*_{image_idx}.bmp', * stand for any number
regist_folder = 'image/regist/';
image_name_regexp = fullfile(regist_folder, ['*_', image_idx, '.bmp']);
files = dir(image_name_regexp);
if isempty(files)
    error('No image found');
end
image_name = fullfile(regist_folder, files(1).name);
image = imread(image_name);
image = im2double(image);
image = im2gray(image);
% Normalize image
image = (image - min(image(:))) / (max(image(:)) - min(image(:)));

%% Parameters
% retrieve parameters from config
block_size = config.block_size;
extended_size = config.extended_size;
threshold = config.threshold;
d = config.d;
mask = config.mask;
smooth_filter_size = config.smooth_filter_size;
smooth_filter_sigma = config.smooth_filter_sigma;
gabor_filter_size = config.gabor_filter_size;
gabor_filter_sigma = config.gabor_filter_sigma;
binarize_sensitivity = config.binarize_sensitivity;
small_object_size = config.small_object_size;
small_branch_size = config.small_branch_size;
prune_length = config.prune_length;
remove_margin_length = config.remove_margin_length;
bridge_length = config.bridge_length;
bridge_d = config.bridge_d;
% Debug flag
debug = false;

%% Image enhancement
[enhanced_image, background] = enhance(image, ...
    block_size, extended_size, threshold, d, mask, ...
    smooth_filter_size, smooth_filter_sigma, ...
    gabor_filter_size, gabor_filter_sigma);

%% Get minutiae
[end_i, end_j, end_direction, bridge_i, bridge_j, bridge_direction, thin_image] = ...
    get_minutiae(enhanced_image, background, binarize_sensitivity, ...
    small_object_size, small_branch_size, prune_length, remove_margin_length, ...
    bridge_length, bridge_d);

%% Concatenate minutiae
% minutiae = 
% end_i & end_j & end_direction \\
% bridge_i & bridge_j & bridge_direction
minutiae = [end_i, end_j, end_direction; ...
    bridge_i, bridge_j, bridge_direction];

%% Debug
if debug
    figure;
    subplot(1, 2, 1);
    imshow(enhanced_image);
    subplot(1, 2, 2);
    imshow(thin_image);
    DrawMinu(gcf, minutiae, 'r');
    saveas(gcf, ['result/process/register/', image_idx, '.png']);
end

%% Save minutiae
save(['result/register/', image_idx, '.mat'], 'minutiae');

end
