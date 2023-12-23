
# Fingerprint Typing

数字图像处理课程大作业. 
我们选择了第三个题目: 指纹打字.
队员: 刘鸣霄(Liu, Monster Kid), 费昕(Fei, Barry)
Contact: mx-liu21@mails.tsinghua.edu.cn

## 项目结构

- `image/`: 存放指纹图片
- `result/`: 存放中间结果, 如特征点mat文件，txt文件和可视化图片
- `solver/`: 四个主要算法: 特征图, 增强, 细节点提取, 指纹匹配
- `utils/`: 一些工具函数
- `main.m`: 主程序: 从这里运行
- `extract_regist_minu, extract_input_minu.m`: 从指纹图像中提取特征点(程序的一部分)
- `match_input.m`: 指纹匹配(程序的一部分)
- `match_python.py`: python版本匹配算法
- `reset.sh`: 重置result文件夹的脚本

## 运行

请从 `main.m` 运行. 

可以按照注释修改 `main.m` 中的控制参数. 如果要查看debug结果, 请修改`config_1`和`config_2`中相应的`debug`参数.

如果要使用 python 版本的匹配算法, 请配置一个3.9版本的 python 环境, 并安装 `numpy`, 将解释器的路径写入 `main.m` 中的 `interpreter_path` 变量.
