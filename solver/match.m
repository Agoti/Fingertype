function matching_score = match(minutiae_1, minutiae_2)

%% Parameters
distance_threshold = 15;
angle_threshold = 30;

%% True matching
max_score = 0;
for i = 1:size(minutiae_1, 1)
    for j = 1:size(minutiae_2, 1)
        score = 0;
        matched_minu_1_1 = [];
        matched_minu_1_2 = [];
        is_matched_1_1 = zeros(size(minutiae_1, 1), 1);
        is_matched_1_2 = zeros(size(minutiae_2, 1), 1);
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
                if norm(minutiae_1(k, 1:2) - minutiae_2_transformed(l, 1:2)) < distance_threshold ...
                    && abs(minutiae_1(k, 3) - minutiae_2_transformed(l, 3)) < angle_threshold ...
                    && is_matched_1_1(k) == 0 && is_matched_1_2(l) == 0
                    score = score + 1;
                    matched_minu_1_1 = [matched_minu_1_1; minutiae_1(k, 1:2)];
                    matched_minu_1_2 = [matched_minu_1_2; minutiae_2(l, 1:2)];
                    is_matched_1_1(k) = 1;
                    is_matched_1_2(l) = 1;
                end
            end
        end
        % Update maximum score
        if score > max_score
            max_score = score;
            max_A = A;
            max_B = b;
            max_matched_minu_1_1 = matched_minu_1_1;
            max_matched_minu_1_2 = matched_minu_1_2;
        end
    end
end

matching_score = max_score;
    
% Show matching result amd compare with ground truth
% if debug
%     disp(['Matching score: ', num2str(max_score)]);
%     disp(['Affine transformation: theta = ', num2str(acos(max_A(1, 1)) * 180 / pi), ', dx = ', num2str(max_B(1)), ', dy = ', num2str(max_B(2))]);
%     figure;
%     subplot(2, 1, 1);
%     showMatchedFeatures(image_1_1, image_1_2, max_matched_minu_1_1, max_matched_minu_1_2, 'montage');
%     subplot(2, 1, 2);
%     showMatchedFeatures(image_1_1, image_1_2, matched_pts1, matched_pts2, 'montage');
%     saveas(gcf, 'result/1_1_1_2.png');
%     tform = affine2d([max_A, max_B; 0, 0, 1]');
%     minutiae_2_transformed(:, 1:2) = transformPointsForward(tform, minutiae_2(:, 1:2));
%     minutiae_2_transformed(:, 3) = minutiae_2(:, 3) + acos(max_A(1, 1));
%     background = ones(size(image_1_1));
%     figure;
%     imshow(background);
%     DrawMinu(gcf, minutiae_1, 'r');
%     DrawMinu(gcf, minutiae_2_transformed, 'b');
%     saveas(gcf, 'result/process/1_1_1_2_minu.png');
% end
