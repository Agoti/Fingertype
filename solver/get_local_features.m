function [magnitude, direction, frequency, ROI] = get_local_features(image, ...
    block_size, extended_size, threshold, d, varargin)

%% parameter check
if nargin == 5
    mask = 0;
else
    mask = varargin{1};
end

%% read and pre-process
[height, width] = size(image);

% the block size and the extended size should be even numbers.
block_size = block_size + mod(block_size, 2);
extended_size = extended_size + mod(extended_size, 2);

% pad image
margin = floor((extended_size - block_size) / 2);
padded_image = ones(ceil(height / block_size) * block_size + 2 * margin, ...
    ceil(width / block_size) * block_size + 2 * margin);
padded_image(margin + 1:margin + height, margin + 1:margin + width) = image;

% the matrices to store the result
num_block_height = ceil(height / block_size);
num_block_width = ceil(width / block_size);
direction = zeros(num_block_height, num_block_width);
magnitude = zeros(num_block_height, num_block_width);
frequency = zeros(num_block_height, num_block_width);
center = floor(extended_size / 2) + 1;

%% compute FFT
for i = 1:num_block_height
    for j = 1:num_block_width

        % get subimage
        row_range = (i - 1) * block_size + (1:extended_size);
        col_range = (j - 1) * block_size + (1:extended_size);
        subimage = padded_image(row_range, col_range);

        % compute FFT
        subimage_fft = fftshift(fft2(subimage));
        magnitude_fft = log(1+abs(subimage_fft));

        % clear DC component
        magnitude_fft(center - d : center + d, center - d : center + d) = 0;

        % find the maximum
        [max_magnitude, max_index] = max(magnitude_fft(:));
        [max_row, max_col] = ind2sub(size(magnitude_fft), max_index);
        magnitude(i, j) = max_magnitude;

        % calculate direction and period;
        angle = atan2(max_col - center, max_row - center) * 180 / pi;
        if angle > 90
            angle = angle - 180;
        elseif angle < -90
            angle = angle + 180;
        end
        direction(i, j) = angle;
        frequency(i, j) = sqrt((max_row - center)^2 + (max_col - center)^2) / extended_size;

    end
end

% has-fingerprint mask
% if mask{1} == "knn"
%     load('data2.mat');
%     label = data2(:, 4);
%     data = data2(:, 1:3);
%     knnClassifier = fitcknn(data, label, 'NumNeighbors', 1);
% 
%     % predict ROI
%     ROI = zeros(num_block_height, num_block_width);
%     for i = 1:num_block_height
%         for j = 1:num_block_width
%             subimage = padded_image((i - 1) * block_size + (1:extended_size), ...
%                 (j - 1) * block_size + (1:extended_size));
%             ROI(i, j) = predict(knnClassifier, [magnitude(i, j), frequency(i, j) * extended_size, var(subimage(:))]);
%         end
%     end
% elseif mask{1} == "gauss" || mask{1} == "guass_freq"
%     ROI_magnitude = magnitude .* ...
%         generate_gauss(num_block_width, num_block_height, mask{2});
%     ROI = ROI_magnitude > threshold;
% else
%     ROI = magnitude > threshold;
% end
ROI = magnitude > threshold;

% deal with the border
% nblock_padmargin = ceil((extended_size - block_size) / 2 / block_size + 1);

% for i = 1:num_block_height
%     for j = 1:num_block_width
%         if ROI(i, j) == 1
%             if (i <= nblock_padmargin || i > num_block_height - nblock_padmargin || ...
%                     j <= nblock_padmargin || j > num_block_width - nblock_padmargin) ...
%                     && (abs(direction(i, j)) < 1e-6 || abs(abs(direction(i, j)) - 90) < 1e-6)
%                 ROI(i, j) = 0;
%             end
%         end
%     end
% end


end
