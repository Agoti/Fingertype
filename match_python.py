# Python minutiae matching algorithm
# Code by Barry

import os
import time
import numpy as np

def count_close_points(arr1, arr2):
    coords1 = arr1[:, :2]
    coords2 = arr2[:, :2]
    angles1 = arr1[:, 3]
    angles2 = arr2[:, 3]
    
    
    dists = np.sqrt(np.sum((coords1[:, np.newaxis, :] - coords2[np.newaxis, :, :]) ** 2, axis=2))
    
    angle_diffs = np.abs(angles1[:, np.newaxis] - angles2[np.newaxis, :])
    angle_diffs = angles1[:, np.newaxis] - angles2[np.newaxis, :]
    angle_diffs = np.abs((angle_diffs + 180) % 360 - 180)
    
    close_points = (dists < 30) & (angle_diffs < 30)
    matched1 = np.full(len(arr1), False)
    matched2 = np.full(len(arr2), False)
    count = 0

    for i in range(len(arr1)):
        for j in range(len(arr2)):
            if close_points[i, j] and not matched1[i] and not matched2[j]:
                count += 1
                matched1[i] = True
                matched2[j] = True
                break
            
    unmatched1 = np.sum(~matched1)
    unmatched2 = np.sum(~matched2)
    penalty = 0.2 * (unmatched1 + unmatched2)
    
    return count - penalty


def calculate_mapping_score(input_data, regist_data):
    # convert to numpy
    input_list = [[d['x_pos'], d['y_pos'], 1, d['dir']] for d in input_data]
    input_arr = np.array(input_list)
    
    regist_list = [[d['x_pos'], d['y_pos'], 1, d['dir']] for d in regist_data]
    regist_arr = np.array(regist_list)
    
    best_score = 0
    
    for input_minu in input_data:
        for regist_minu in regist_data:

            dx = input_minu['x_pos'] - regist_minu['x_pos']
            dy = input_minu['y_pos'] - regist_minu['y_pos']
            rot = input_minu['dir'] - regist_minu['dir']
            if rot > 180:
                rot = rot - 360
            elif rot < -180:
                rot = rot + 360
            rots = rot / 180 * np.pi

            R = np.array([[np.cos(rots), -np.sin(rots), dx],
                         [np.sin(rots), np.cos(rots), dy],
                         [0, 0, 1]])
            
            transformed_regist_arr = np.zeros_like(regist_arr)
            transformed_regist_arr[:, :3] = (R @ regist_arr[:, :3].T).T
            transformed_regist_arr[:, 3] = regist_arr[:, 3] + rot
            
            score = count_close_points(input_arr, transformed_regist_arr)
            if score >= best_score:
                best_score = score
               
    return best_score
    
def matching():
    # print('start matching...')
    input_minu_dir = 'result/input_txt'
    regist_minu_dir = 'result/register_txt'

    input_file_list = []
    register_file_list = []

    for file in os.listdir(input_minu_dir):
        input_file_list.append(os.path.join(input_minu_dir, file))

    for file in os.listdir(regist_minu_dir):
        register_file_list.append(os.path.join(regist_minu_dir, file))

    input_data_dict = {}
    regist_data_dict = {}
    # print('checkpoint 1')

    # load data
    for input in input_file_list:
        # print('checkpoint 2')
        # load input
        input_data = []
        with open(input, 'r') as f:
            for line in f:
                x_pos, y_pos, dir = map(int, line.strip().split())
                input_data.append({
                    'x_pos': x_pos,
                    'y_pos': y_pos,
                    'dir': dir + 180
                })
        input_data_dict[os.path.basename(input)] = input_data

        
    for regist in register_file_list:
        # load regist
        regist_data = []
        with open(regist, 'r') as f:
            for line in f:
                x_pos, y_pos, dir = map(int, line.strip().split())
                regist_data.append({
                    'x_pos': x_pos,
                    'y_pos': y_pos,
                    'dir': dir + 180
                })
        regist_data_dict[os.path.basename(regist)] = regist_data
        
    input_data_dict = {k: v for k, v in sorted(input_data_dict.items(), key=lambda item: int(item[0][:-4]))}
    result = ""
    for input_name, input_data in input_data_dict.items():
        t_start = time.time()
        best_score = 0
        best_mapping = ''

        for regist_name, regist_data in regist_data_dict.items():
            score = calculate_mapping_score(input_data, regist_data)
            if score > best_score:
                best_score = score
                best_mapping = regist_name
                
        t_end = time.time()
        
        print(f'Matching {input_name} to {best_mapping} in {t_end - t_start} seconds... ')
        char = best_mapping[2:-4]
        if char == 'space':
            char = '_'
        result += char

    print(f"result: {result}")

if __name__ == '__main__':
    matching()
        
# Matlab 配置 Python
# Step 1:
# pyenv('Version', '/Users/barry/anaconda3/envs/matlab+3.9/bin/python3.9')
# Step 2:

# if count(py.sys.path, '/Users/barry/Downloads/Image Processing/小作业6') == 0
#     insert(py.sys.path, int32(0), '/Users/barry/Downloads/Image Processing/小作业6');
# end

# py.importlib.import_module('mapping')
