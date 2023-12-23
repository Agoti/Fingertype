% Function used to convert mat file to txt file
% Code by Monster Kid

function mat2txt()

%% The directory of mat file and txt file
mat_dir = 'result/register';
txt_dir = 'result/register_txt';
mat_dir_2 = 'result/input';
txt_dir_2 = 'result/input_txt';

% create txt directory
if ~exist(txt_dir, 'dir')
    mkdir(txt_dir);
end
if ~exist(txt_dir_2, 'dir')
    mkdir(txt_dir_2);
end

%% convert for registered
mat_list = dir(fullfile(mat_dir, '*.mat'));
for i = 1:length(mat_list)
    mat_path = fullfile(mat_dir, mat_list(i).name);
    txt_path = fullfile(txt_dir, mat_list(i).name);
    mat2txt_sub(mat_path, txt_path);
end

%% convert for input
mat_list = dir(fullfile(mat_dir_2, '*.mat'));
for i = 1:length(mat_list)
    mat_path = fullfile(mat_dir_2, mat_list(i).name);
    txt_path = fullfile(txt_dir_2, mat_list(i).name);
    mat2txt_sub(mat_path, txt_path);
end

end



%% Utility function to convert a single file
function mat2txt_sub(mat_path, txt_path)

load(mat_path);
x = minutiae(:, 1);
y = minutiae(:, 2);
angle = minutiae(:, 3);
% convert angle to int
angle = round(angle);

% create txt file
fid = fopen([txt_path(1:end-4), '.txt'], 'w');
for i = 1:length(x)
    fprintf(fid, '%d %d %d\n', x(i), y(i), angle(i));
end
fclose(fid);

end
