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

[matching_score, A, B, matched_pts1, matched_pts2] = ...
    match_mex(minutiae_1, minutiae_2, dist_threshold, angle_threshold, ...)
    penalty_translation, penalty_rotation, penalty_unmatched_minutiae);
    
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
