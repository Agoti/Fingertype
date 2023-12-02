function result = match_input(image_idx)

    register_dir = "result/register/";
    % Registered minutiae: "a.mat"
    minutiae_files = dir(register_dir + "*.mat");
    num_files = length(minutiae_files);
    register_list= cell(num_files, 1);
    for i = 1:num_files
        file_name = minutiae_files(i).name;
        load(register_dir + file_name);
        register_list{i} = struct('letter', file_name(1), 'minutiae', minutiae);
    end

    % Input minutiae
    input_dir = "result/input/";
    load(input_dir + image_idx + ".mat");
    minutiae_input = minutiae;

    % Match
    max_score = 0;
    result = 'none';
    for i = 1:num_files
        letter = register_list{i}.letter;
        minutiae_register = register_list{i}.minutiae;
        matching_score = match(minutiae_input, minutiae_register);
        if matching_score > max_score
            max_score = matching_score;
            result = letter;
        end
    end

end
