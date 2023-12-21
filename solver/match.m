function [matching_score, A, B, matched_pts1, matched_pts2] ...
    = match(minutiae_1, minutiae_2, config)

%% Parameters
% Retrieve parameters from config
dist_threshold = config.dist_threshold;
angle_threshold = config.angle_threshold;
penalty_translation = config.translation_penalty;
penalty_rotation = config.rotation_penalty;
penalty_unmatched_minutiae = config.unmatched_penalty;
debug = config.debug_match;

% Iterative matching
max_score = -inf;
for i = 1:size(minutiae_1, 1)
    for j = 1:size(minutiae_2, 1)
        score = 0;
        matched_1 = [];
        matched_2 = [];
        is_matched_1 = zeros(size(minutiae_1, 1), 1);
        is_matched_2 = zeros(size(minutiae_2, 1), 1);
        % Calculate affine transformation
        dx = minutiae_1(i, 1) - minutiae_2(j, 1);
        dy = minutiae_1(i, 2) - minutiae_2(j, 2);
        dtheta = minutiae_1(i, 3) - minutiae_2(j, 3);
        A = [cos(dtheta), -sin(dtheta); sin(dtheta), cos(dtheta)];
        b = [dx; dy];
        tform = affine2d([A, b; 0, 0, 1]');
        % Transform image 1_2
        minutiae_2_transformed(:, 1:2) = transformPointsForward(tform, minutiae_2(:, 1:2));
        minutiae_2_transformed(:, 3) = minutiae_2(:, 3) + dtheta;
        % Calculate matching score
        % Matching score = number of matched minutiae
        for k = 1:size(minutiae_1, 1)
            for l = 1:size(minutiae_2_transformed, 1)
                if norm(minutiae_1(k, 1:2) - minutiae_2_transformed(l, 1:2)) < dist_threshold ...
                    && abs(minutiae_1(k, 3) - minutiae_2_transformed(l, 3)) < angle_threshold ...
                    && is_matched_1(k) == 0 && is_matched_2(l) == 0
                    score = score + 1;
                    matched_1 = [matched_1; minutiae_1(k, 1:2)];
                    matched_2 = [matched_2; minutiae_2(l, 1:2)];
                    is_matched_1(k) = 1;
                    is_matched_2(l) = 1;
                end
            end
        end
        % update matching score
        % incur penalty for unmatched minutiae and affine transformation
        score = score - penalty_unmatched_minutiae * (size(minutiae_1, 1) - sum(is_matched_1)) - penalty_unmatched_minutiae * (size(minutiae_2, 1) - sum(is_matched_2));
        score = score - penalty_rotation * abs(dtheta) * 180 / pi - penalty_translation * (abs(dx) + abs(dy));
        % Update maximum score
        if score > max_score
            max_score = score;
            max_A = A;
            max_B = b;
            max_matched_1 = matched_1;
            max_matched_2 = matched_2;
        end
    end
end

% Return result
matching_score = max_score;
A = max_A;
B = max_B;
matched_pts1 = max_matched_1;
matched_pts2 = max_matched_2;
    
%% Debug: Show matching result amd compare with ground truth
if debug
    disp(['Matching score: ', num2str(max_score)]);
    disp(['Affine transformation: theta = ', num2str(acos(max_A(1, 1)) * 180 / pi), ', dx = ', num2str(max_B(1)), ', dy = ', num2str(max_B(2))]);
    figure;
    showMatchedFeatures(image_1_1, image_1_2, matched_pts1, matched_pts2, 'montage');
    tform = affine2d([A, B; 0, 0, 1]');
    minutiae_2_transformed(:, 1:2) = transformPointsForward(tform, minutiae_2(:, 1:2));
    minutiae_2_transformed(:, 3) = minutiae_2(:, 3) + acos(max_A(1, 1));
    background = ones(size(image_1_1));
    figure;
    imshow(background);
    DrawMinu(gcf, minutiae_1, 'r');
    DrawMinu(gcf, minutiae_2_transformed, 'b');
end
