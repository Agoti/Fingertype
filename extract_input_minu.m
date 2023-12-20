function minutiae = extract_input_minu(image, config, varargin)

if nargin == 3
    key = varargin{1};
else
    key = 'none';
end

% Normalize image
image = im2double(image);
image = im2gray(image);
image = (image - min(image(:))) / (max(image(:)) - min(image(:)));

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
debug = config.debug_input;

    %% Image enhancement
[enhanced_image, background] = enhance(image, ...
    block_size, extended_size, threshold, d, mask, ...
    smooth_filter_size, smooth_filter_sigma, ...
    gabor_filter_size, gabor_filter_sigma, config.debug_enhance);

%% Get minutiae
[end_i, end_j, end_direction, bridge_i, bridge_j, bridge_direction, thin_image] = ...
    get_minutiae(enhanced_image, background, binarize_sensitivity, ...
    small_object_size, small_branch_size, prune_length, remove_margin_length, ...
    bridge_length, bridge_d);

%% Concatenate minutiae
% minutiae = 
% end_i & end_j & end_direction \\
% bridge_i & bridge_j & bridge_direction
minutiae = [end_j, end_i, end_direction; ...
    bridge_j, bridge_i, bridge_direction];

%% Debug
if debug
    figure;
    set(gcf, 'Position', [0, 0, 1200, 400]);
    subplot(1, 3, 1);
    imshow(image);
    subplot(1, 3, 2);
    imshow(enhanced_image);
    subplot(1, 3, 3);
    imshow(thin_image);
    DrawMinu(gcf, minutiae, 'r');
    saveas(gcf, ['result/process/input/', key, '.png']);
end

% Save result
save(['result/input/', key, '.mat'], 'minutiae');

end
