% FingerPrint Enhancement
% By: Monster Kid

function [enhanced_image, background] = enhance(image, ...
    block_size, extended_size, threshold, d, mask, ...
    smooth_filter_size, smooth_filter_sigma, ...
    gabor_filter_size, gabor_filter_sigma)

%% parameters
debug1 = 0;
[height, width] = size(image);

%% get magnitude, period and direction locally
[magnitude, direction, frequency, ROI] = ...
    get_local_features(image, block_size, extended_size, threshold, d, mask);

% %% debug: display magnitude, period and direction
if debug1
    figure;
    subplot(2, 2, 1);
    imshow(magnitude, []);
    title('magnitude');
    subplot(2, 2, 2);
    imshow(frequency, []);
    title('frequency');
    subplot(2, 2, 3);
    imshow(image, []);
    DrawDir(gcf, direction, block_size, 'g', ROI);
    title('direction');
    subplot(2, 2, 4);
    imshow(ROI, []);
    title('ROI');
end


%% filter and smooth

% get guass filter
guass = generate_gauss(smooth_filter_size, smooth_filter_size, smooth_filter_sigma);
guass = guass / sum(guass(:));

% filter frequency
frequency = imfilter(frequency, guass, 'replicate', 'same', 'conv');

% smooth direction
direction = direction / 180 * pi * 2;
direction_cos = cos(direction);
direction_sin = sin(direction);
direction_cos = imfilter(direction_cos, guass, 'replicate', 'same', 'conv');
direction_sin = imfilter(direction_sin, guass, 'replicate', 'same', 'conv');
direction = atan2(direction_sin, direction_cos) / 2 / pi * 180;

% %% debug: display filtered period and direction
if debug1
    figure;
    subplot(2, 2, 1);
    imshow(magnitude, []);
    title('magnitude');
    subplot(2, 2, 2);
    imshow(frequency, []);
    title('frequency');
    subplot(2, 2, 3);
    imshow(image, []);
    DrawDir(gcf, direction, block_size, 'b', ROI);
    title('direction');
    subplot(2, 2, 4);
    imshow(ROI, []);
    title('ROI');
end

%% filter each local region with gabor filter
num_block_height = size(ROI, 1);
num_block_width = size(ROI, 2);
enhanced_image = ones(size(image));
background = false(size(image));

% pad image
margin = floor((extended_size - block_size) / 2);
padded_image = ones(ceil(height / block_size) * block_size + 2 * margin,...
    ceil(width / block_size) * block_size + 2 * margin);
padded_image(margin + 1:margin + height, margin + 1:margin + width) = image;

% loop each local region
for i = 1:num_block_height
    for j = 1:num_block_width


        % get subimage
        row_range = (i - 1) * block_size + (1:extended_size);
        col_range = (j - 1) * block_size + (1:extended_size);
        row_range_original = (i - 1) * block_size + (1:block_size);
        col_range_original = (j - 1) * block_size + (1:block_size);
        subimage = padded_image(row_range, col_range);

        % get background
        % if the local region does not contain fingerprint, skip
        if ROI(i, j) == 0
            background(row_range_original, col_range_original) = true;
            continue;
        end

        % get gabor filter
        gabor = generate_gabor(gabor_filter_size, gabor_filter_size, gabor_filter_sigma, 90-direction(i, j), frequency(i, j), 90);

        % filter subimage
        subimage_filtered = imfilter(subimage, gabor, 'replicate', 'same', 'conv');

        % save filtered local region
        enhanced_image(row_range_original, col_range_original) = subimage_filtered(margin + 1:margin + block_size, margin + 1:margin + block_size);
    end
end

enhanced_image = enhanced_image(1:height, 1:width);
background = background(1:height, 1:width);
enhanced_image(find(enhanced_image < 0)) = 0;
enhanced_image(find(enhanced_image > 1)) = 1;

end
