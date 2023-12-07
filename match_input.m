function result = match_input(image_idx, config_2)

    register_dir = "result/register/";
    register_img_dir = "image/regist";
    % Registered minutiae: "a.mat"
    minutiae_files = dir(register_dir + "*.mat");
    num_files = length(minutiae_files);
    register_list= cell(num_files, 1);
    for i = 1:num_files
        file_name = minutiae_files(i).name;
        % Remove ".mat"
        file_name = file_name(1:end-4);
        load(register_dir + file_name + ".mat");
        image_register = imread(register_img_dir + "/" + file_name + ".bmp");
        register_list{i} = struct('name', file_name, 'minutiae', minutiae, 'image', image_register);
    end

    % Input minutiae
    input_dir = "result/input/";
    load(input_dir + image_idx + ".mat");
    minutiae_input = minutiae;
    input_img_dir = "image/input";
    image_input = imread(input_img_dir + "/" + image_idx + ".bmp");

    % Debug flag
    debug = config_2.debug_matchinput;
    N = config_2.debug_ninput;

    % Match
    % Keep track of N best matches: 5 * struct(letter, score, ...)
    match_info_struct = struct('name', ' ', 'score', -inf, 'A', 0, 'B', 0, 'matched_pts1', 0, 'matched_pts2', 0);
    top_N_matches = repmat(match_info_struct, N, 1);
    for i = 1:num_files

        name = register_list{i}.name;
        minutiae_register = register_list{i}.minutiae;

        [matching_score, A, B, matched_pts1, matched_pts2] = ...
            match(minutiae_input, minutiae_register, config_2);

        % Check if the current matching_score is greater than the smallest score in top_N
        if matching_score > min([top_N_matches.score])
            % Find the index of the smallest score in top_N
            [~, idx] = min([top_N_matches.score]);
            
            % Update the N best matches
            top_N_matches(idx) = struct('name', name, 'score', matching_score, 'A', A, 'B', B, 'matched_pts1', matched_pts1, 'matched_pts2', matched_pts2);
        end
    end

    % Sort top_N_matches by score
    [~, idx] = sort([top_N_matches.score], 'descend');
    top_N_matches = top_N_matches(idx);
    result = top_N_matches(1).name(3:end);

    if debug
        fprintf("Top %d matches:\n", N);
        for i = 1:N
            % Print the name, score, theta, tx, ty of the best match
            fprintf("%d. %s: %f ", i, top_N_matches(i).name(3:end), top_N_matches(i).score);
            fprintf("theta: %f, tx: %f, ty: %f\n", acos(top_N_matches(i).A(1, 1)), top_N_matches(i).B(1), top_N_matches(i).B(2));
            % retrieve the minutiae and image of the best match
            % Every name of the register_list
            names = cellfun(@(x) x.name, register_list, 'UniformOutput', false);
            reg_idx = find(strcmp(names, top_N_matches(i).name));
            register = register_list{reg_idx};
            minutiae_register = register.minutiae;
            image_register = register.image;
            matched_pts1 = top_N_matches(i).matched_pts1;
            matched_pts2 = top_N_matches(i).matched_pts2;
            A = top_N_matches(i).A;
            B = top_N_matches(i).B;
            % Plot the matched points and minutiae
            figure;
            showMatchedFeatures(image_input, image_register, matched_pts1, matched_pts2, 'montage');
            saveas(gcf, "result/match/" + image_idx + "_" + i + "_" + top_N_matches(i).name(3:end) + "_matchpoints.png");
            tform = affine2d([A, B; 0, 0, 1]');
            minutiae_register(:, 1:2) = transformPointsForward(tform, minutiae_register(:, 1:2));
            minutiae_register(:, 3) = minutiae_register(:, 3) + acos(A(1, 1));
            background = ones(size(image_register, 1), size(image_register, 2));
            figure;
            imshow(background);
            DrawMinu(gcf, minutiae_input, 'r');
            DrawMinu(gcf, minutiae_register, 'b');
            saveas(gcf, "result/match/" + image_idx + "_" + i + "_" + top_N_matches(i).name(3:end) + "_minutiae.png");
        end
    end

end
