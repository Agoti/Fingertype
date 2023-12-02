% get_minutiae.m
% Get the minutiae of the fingerprint image
% Input:
%  image: the fingerprint image
%  background: the background of the fingerprint image
%  binarize_sensitivity: the sensitivity of the binarization
%  small_object_size: the size of the small objects to be removed
%  small_branch_size: the size of the small branches to be removed
%  prune_length: the length of the pruning
%  remove_margin_length: the length of the margin to be removed
%  bridge_length: the length of the bridge to be removed
%  bridge_d: the diameter of the bridge to be removed
% Output:
%   end_i: the row index of the end points
%   end_j: the column index of the end points
%   end_points_direction: the direction of the end points
%   branch_i: the row index of the branch points
%   branch_j: the column index of the branch points
%   branch_points_direction: the direction of the branch points
function [end_i, end_j, end_points_direction, branch_i,...
     branch_j, branch_points_direction, thin_image] = get_minutiae(image, background, ...
     binarize_sensitivity, small_object_size, small_branch_size, ...
     prune_length, remove_margin_length, bridge_length, bridge_d)

%% Debug flag
debug = false;

%% Image binarize
image = imbinarize(image, 'adaptive', 'ForegroundPolarity', 'dark', 'Sensitivity', binarize_sensitivity);
% Remove small objects, fill holes and spurs
image = bwareaopen(image, small_object_size);
image = ~image;
image = bwareaopen(image, small_object_size);
image = ~image;
image = bwmorph(image, 'diag');
% Open the image by 1 pixel
% se = strel('disk', 1);
% image = imopen(image, se);
binarized_image = image;

%% Image thinning
% Invert the image
image = ~image;
% Thin the image
image = bwmorph(image, 'thin', Inf);

%% Image pruning
% Pad the background by 1 pixel, then dialate it by 1 pixel
background = padarray(background, [1, 1]);
background = imdilate(background, strel('disk', remove_margin_length));
% Pad the image by 1 pixel
image_prune = padarray(image, [1, 1]);
% Prune the image
image_prune = prune(image_prune, background, prune_length, false);
image_prune = bwareaopen(image_prune, small_branch_size);
image = image_prune(2:end-1, 2:end-1);
background = background(2:end-1, 2:end-1);

%% Substract feature points
% invert the image back
image = ~image;
[~, branch_points] = get_end_branch_points(image);
% Mark end points and branch points
[bp_i, bp_j] = find(branch_points);
% Tackle the bridge problem, remove the branch points,
% which are too close to each other, then remove
% short branches, then add the branch points back
image = ~image;
temp_image = image;
% Fist dialate the branch points
branch_points = imdilate(branch_points, strel('disk', bridge_d));
image = image & ~branch_points;
% For each pair of branch points, if the distance between them is less than
% bridge_length, then remove the point in the middle
for i = 1:length(bp_i)
    for j = i+1:length(bp_i)
        if norm([bp_i(i), bp_j(i)] - [bp_i(j), bp_j(j)]) < bridge_length
            middle_i = round((bp_i(i) + bp_i(j)) / 2);
            middle_j = round((bp_j(i) + bp_j(j)) / 2);
            image(middle_i, middle_j) = 0;
        end
    end
end
% Remove short branches
image = bwareaopen(image, prune_length);
% Add the branch points back
image = image | (branch_points & temp_image);
image = prune(image, background, 2, false);

image = ~image;
thin_image = image;
[end_points, branch_points] = get_end_branch_points(image);
% Verify the end points and branch points, remove the points, which are too
% close to the border
padded_image = padarray(image, [25, 25], 1);
border = imopen(padded_image, strel('disk', 20));
border = imdilate(border, strel('disk', remove_margin_length));
border = border(26:end-25, 26:end-25);
end_points = end_points & ~border;
branch_points = branch_points & ~border;


%% Calculate the direction of end points and branch points
% Calculate the direction of end points
% Walk along the skeleton by 10 pixels, and calculate the direction
direction_step = 10;
[end_i, end_j] = find(end_points);
end_points_direction = zeros(size(end_i));
for i = 1:length(end_i)
    direction = get_direction(image, end_i(i), end_j(i), direction_step, 1);
    end_points_direction(i) = direction;
end
% Calculate the direction of branch points
[branch_i, branch_j] = find(branch_points);
branch_points_direction = zeros(size(branch_i));
for i = 1:length(branch_i)
    direction = get_direction(image, branch_i(i), branch_j(i), direction_step, 2);
    branch_points_direction(i) = direction;
end

end_points_direction = end_points_direction * 180 / pi;
branch_points_direction = branch_points_direction * 180 / pi;

%% Debug
if debug
    figure;
    subplot(2, 3, 1);
    imshow(original_image);
    title('Original image');
    subplot(2, 3, 2);
    imshow(enhanced_image);
    title('Enhanced image');
    subplot(2, 3, 3);
    imshow(binarized_image);
    title('Binarized image');
    subplot(2, 3, 4);
    imshow(thin_image);
    title('Thinned image');
    % concatenate the end points and branch points
    points = [end_j, end_i; branch_j, branch_i];
    subplot(2, 3, 5);
    imshow(image);
    DrawMinu(gcf, points);
    title('Minutiae');
    % consider direction
    points_direction = [end_j, end_i, end_points_direction; branch_j, branch_i, branch_points_direction];
    subplot(2, 3, 6);
    imshow(image);
    DrawMinu(gcf, points_direction);
    title('Minutiae with direction');
    linkaxes;
end

end

%% Function to prune the fingerprint image
% Referred to Pr. Feng's code
function output = prune(image, background, len, varargin)

    if nargin == 3
        varargin{1} = false;
    end
    prune_border = varargin{1};
    
    % create the structuring element for the endpoint detection
    B = create_endpoint_SE();

    % prune the image
    X1 = bwmorph(image, 'spur', len);
    % X1 = image;
    % for k = 1:len
    %     endpoints = false(size(image));
    %     for i = 1:8
    %         endpoints = endpoints | bwhitmiss(image, B(:, :, i, 1), B(:, :, i, 2));
    %     end
    %     X1(endpoints) = 0;
    % end

    % get the endpoints
    X2 = false(size(image));
    for i = 1:8
        endpoints = bwhitmiss(X1, B(:, :, i, 1), B(:, :, i, 2));
        X2(endpoints) = 1;
    end

    % dilate the endpoints
    se = strel(ones(3, 3));
    if prune_border
        X3 = X2 & ~background;
    else
        X3 = X2;
    end

    for k = 1:len
        X3 = imdilate(X3, se) & image;
    end

    % combine the endpoints and the pruned image
    output = X3 | X1;
end

%% function to create the structuring element for the endpoint detection
function B = create_endpoint_SE()
    B = zeros(3, 3, 8, 2);
    B(:, :, 1, 1) = [0 0 0; 1 1 0; 0 0 0];
    B(:, :, 1, 2) = [0 1 1; 0 0 1; 0 1 1];
    for k = 2:4
        B(:, :, k, 1) = imrotate(B(:, :, k-1, 1), 90);
        B(:, :, k, 2) = imrotate(B(:, :, k-1, 2), 90);
    end
    B(:, :, 5, 1) = [1 0 0; 0 1 0; 0 0 0];
    B(:, :, 5, 2) = ~B(:, :, 5, 1);
    for k = 6:8
        B(:, :, k, 1) = imrotate(B(:, :, k-1, 1), 90);
        B(:, :, k, 2) = imrotate(B(:, :, k-1, 2), 90);
    end
end

%% Function to get end points and branch points of the fingerprint image
% the image has white background and black foreground
function [end_points, branch_points] = get_end_branch_points(image)
    % feature point is defined by the cross number of each pixel, 
    % cn(p) = 0.5 * sum_{i=1}^{8} |b_i - b_{i+1}|
    % calculate the cross number of each pixel
    cn = zeros(size(image));
    for i = 1:size(image, 1)
        for j = 1:size(image, 2)
            if image(i, j) == 1
                continue;
            end
            if i == 1 || i == size(image, 1) || j == 1 || j == size(image, 2)
                cn(i, j) = 2;
                continue;
            end
            b = zeros(1, 8);
            b(1) = image(i-1, j);
            b(2) = image(i-1, j+1);
            b(3) = image(i, j+1);
            b(4) = image(i+1, j+1);
            b(5) = image(i+1, j);
            b(6) = image(i+1, j-1);
            b(7) = image(i, j-1);
            b(8) = image(i-1, j-1);
            cn(i, j) = 0.5 * sum(abs(b(1:7) - b(2:8))) + 0.5 * abs(b(8) - b(1));
        end
    end
    % Get end points and branch points image
    end_points = cn == 1;
    branch_points = cn >= 3;

end


%% Function to get the direction of the minutiae
function direction = get_direction(image, i, j, direction_step, type)
% Get the direction of the skeleton at (i, j)
% Walk along the skeleton by direction_step pixels, and calculate the direction
% The direction is calculated by the difference between the first and the last
% point

% type = 1: end points, type = 2: branch points

% keep track of visited points
trace = zeros(size(image));
trace(i, j) = 1;
% it's equivalent to a bfs search problem with a depth of direction_step
frontier = [i, j];
for l1 = 1:direction_step
    next_frontier = [];
    for l2 = 1:size(frontier)
        update = false;
        ii = frontier(l2, 1);
        jj = frontier(l2, 2);
        % get the neighbor of the current point
        neighbor = get_neighbor(image, ii, jj);
        % push the neighbor into the frontier
        for l3 = 1:size(neighbor, 1)
            iii = neighbor(l3, 1);
            jjj = neighbor(l3, 2);
            if trace(iii, jjj) == 0
                trace(iii, jjj) = 1;
                next_frontier = [next_frontier; [iii, jjj]];
                update = true;
            end
        end
        if ~update
            next_frontier = [next_frontier; [ii, jj]];
        end
    end
    frontier = next_frontier;
end

if type == 1
    % end points
    angles = zeros(size(frontier, 1), 1);
    % calculate the angle of each point
    for l1 = 1:size(frontier, 1)
        points = frontier(l1, :);
        angles(l1) = atan2(points(1) - i, points(2) - j);
    end
    % direction is the average of the angles
    direction = mean(angles);
else
    % branch points
    % if two points direction is close enough, then the direction of the branch point
    % is the average of the two points
    angles = zeros(size(frontier, 1), 1);
    % calculate the angle of each point
    for l1 = 1:size(frontier, 1)
        points = frontier(l1, :);
        angles(l1) = atan2(points(1) - i, points(2) - j);
    end
    % find the direction
    closest_angle = Inf;
    for l1 = 1:size(frontier, 1)
        for l2 = l1+1:size(frontier, 1)
            % calculate the difference between the two angles
            % N.B. the difference between 0 and 2*pi is 0
            is_negative = false;
            diff_angle = abs(angles(l1) - angles(l2));
            if diff_angle > pi
                diff_angle = 2*pi - diff_angle;
                is_negative = true;
            end
            if diff_angle < closest_angle
                closest_angle = diff_angle;
                % be careful about -pi and pi
                if is_negative
                    direction = (angles(l1) + angles(l2)) / 2 - pi;
                    if direction < -pi
                        direction = direction + 2*pi;
                    end
                else
                    direction = (angles(l1) + angles(l2)) / 2;
                end
            end
        end
    end
end

direction = -direction;

end

%% Function to get the neighbor of the skeleton at (i, j)
function neighbor = get_neighbor(image, i, j)
% Get the neighbor of the skeleton at (i, j)
% The neighbor is all of the black pixels around (i, j)
% Assume the skeleton is 1 pixel wide and the background is 1
[height, width] = size(image);
neighbor = [];
for di = -1:1
    for dj = -1:1
        if di == 0 && dj == 0
            continue
        end
        if i+di < 1 || i+di > height || j+dj < 1 || j+dj > width
            continue
        end
        if image(i+di, j+dj) == 0
            neighbor = [neighbor; [i+di, j+dj]];
        end
    end
end
end
