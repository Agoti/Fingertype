% match_input.m
% One part of the fingerprint recognition system
% Match input fingerprints with registered fingerprints
% Input: config_1, config_2(look at main.m for more details)
%   - config_1: configuration for minutiae extraction
%   - config_2: configuration for minutiae matching
% Output: result, time_match_total
%   - result: the result of matching(string)
%   - time_match_total: total time for matching
% Code by Monster Kid

function [result, time_match_total] = match_input(config_1, config_2)

    %% Retrieve folder paths
    regist_image_folder = config_2.regist_image_folder;
    input_image_folder = config_2.input_image_folder;
    regist_minu_folder = config_2.regist_minu_folder;
    input_minu_folder = config_2.input_minu_folder;

    %% Load minutiae of all registered images
    % The minutiae of registered images are stored in .mat files
    regist_minu_files = dir(regist_minu_folder + "*.mat");
    n_minu_files = length(regist_minu_files);
    register_list= cell(n_minu_files, 1);
    for i = 1:n_minu_files
        % Retrieve the name of the file
        file_name = regist_minu_files(i).name;
        % Remove ".mat" from the name to get the key
        key = file_name(1:end-4);
        % Load minutiae
        load([regist_minu_folder, file_name]);
        % Load image
        image_register = imread([regist_image_folder, key, config_2.file_type]);
        % Store image and minutiae in register_list
        register_list{i} = struct('key', key, 'minutiae', minutiae, 'image', image_register);
    end

    %% Match input fingerprints
    % Debug flag
    debug = config_2.debug_matchinput;
    N = config_2.debug_matchinput_showtopN;
    % Directory of input images
    input_files = dir(input_image_folder + "*" + config_2.file_type);
    % Put "10.png" at the end of the list
    input_files = input_files([1, 3, 4, 5, 6, 7, 8, 9, 10, 2]);
    % Returns
    result = "";
    time_match_total = 0;

    % Iterate through all input images
    for i = 1:length(input_files)
        disp("Matching " + input_files(i).name + "...");
        tic;
        % Retrieve the name of the file
        name = input_files(i).name;
        % Remove ".png"
        key = name(1:end-4);
        image_input = imread([input_image_folder, name]);
        % Extract minutiae of input image
        minutiae_input = extract_input_minu(image_input, config_1, key);
        % This struct array is used to keep track of N best matches:
        match_info_struct = struct('key', 'none', 'score', -inf, 'A', 0, 'B', 0, 'matched_pts1', 0, 'matched_pts2', 0);
        top_N_matches = repmat(match_info_struct, N, 1);
        % Match input image with all registered images
        for j = 1:n_minu_files

            % Retrieve minutiae and key of the register list
            key = register_list{j}.key;
            minutiae_register = register_list{j}.minutiae;

            % Match minutiae
            [matching_score, A, B, matched_pts1, matched_pts2] = ...
                match(minutiae_input, minutiae_register, config_2);

            % Update top_N_matches if matching_score is larger than the smallest score in top_N
            if matching_score > min([top_N_matches.score])
                % Find the index of the smallest score in top_N
                [~, idx] = min([top_N_matches.score]);
                % Update
                top_N_matches(idx) = struct('key', key, 'score', matching_score, 'A', A, 'B', B, 'matched_pts1', matched_pts1, 'matched_pts2', matched_pts2);
            end
        end

        % Sort top_N_matches by score
        [~, idx] = sort([top_N_matches.score], 'descend');
        top_N_matches = top_N_matches(idx);

        % The result is the best match
        res = top_N_matches(1).key(3:end);
        if res == "space"
            res = "_";
        end
        % Time for matching one image, add to total time
        time_match = toc;
        disp("Result: " + res + " (" + time_match + "s)");
        result = result + res;
        time_match_total = time_match_total + time_match;

        % Show top N matches(when debug is true)
        if debug
            close all;
            fprintf("Top %d matches:\n", N);
            for j = 1:N
                % Print the name, score, theta, tx, ty of the best match
                fprintf("%d. %s: %f ", j, top_N_matches(j).key(3:end), top_N_matches(j).score);
                fprintf("theta: %f, tx: %f, ty: %f\n", acos(top_N_matches(j).A(1, 1)) * 180 / pi, top_N_matches(j).B(1), top_N_matches(j).B(2));
                % Retrieve values from top_N_matches
                keys = cellfun(@(x) x.key, register_list, 'UniformOutput', false);
                reg_key = find(strcmp(keys, top_N_matches(j).key));
                register = register_list{reg_key};
                minutiae_register = register.minutiae;
                image_register = register.image;
                matched_pts1 = top_N_matches(j).matched_pts1;
                matched_pts2 = top_N_matches(j).matched_pts2;
                A = top_N_matches(j).A;
                B = top_N_matches(j).B;
                % Plot the matched points and minutiae
                figure;
                showMatchedFeatures(image_input, image_register, matched_pts1, matched_pts2, 'montage');
                saveas(gcf, "result/match/" + i + "_" + top_N_matches(j).key(3:end) + "_matched.png");
                tform = affine2d([A, B; 0, 0, 1]');
                minutiae_register(:, 1:2) = transformPointsForward(tform, minutiae_register(:, 1:2));
                minutiae_register(:, 3) = minutiae_register(:, 3) + acos(A(1, 1));
                background = ones(size(image_register, 1), size(image_register, 2));
                % Plot the matched minutiae in red and blue
                figure;
                imshow(background);
                DrawMinu(gcf, minutiae_input, 'r');
                DrawMinu(gcf, minutiae_register, 'b');
                saveas(gcf, "result/match/" + i + "_" + top_N_matches(j).key(3:end) + "_minutiae.png");
            end
        end
    end

end
