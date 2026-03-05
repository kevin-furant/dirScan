#!/usr/bin/env python
"""
该脚本用于通过上级目录列表，对下级目录中的文件夹进行按姓名归类
打印生成yaml文件,用于snakemake流程调用
"""
import argparse
from pathlib import Path
import pwd
import yaml

def traverse_dir(input_dir):
    "遍历目录,按key为属主将目录存放到字典中"
    result_dict = []
    for p in input_dir.iterdir():
        if p.is_dir(follow_symlinks=False):
            user_name = pwd.getpwuid(p.stat().st_uid).pw_name
            if result_dict.get(user_name):
                result_dict[user_name].append(p)
            else:
                result_dict[user_name] = [p]
    return result_dict

def main():
    parser = argparse.ArgumentParser(  
        description='此脚本用来打印生成扫盘流程的配置文件config.yml')  
    parser.add_argument(  
        '--pipe_path','-p', dest="pipe", metavar='pipe', type=str, default="/public/work/Personal/fuxiangke/pipeline/userDirScanner",
        help='流程所在路径')  
    parser.add_argument(  
        '--wk_path', '-w', dest="work", metavar='work', type=str, default="/public/work/Personal/fuxiangke/dirScan",
        help='扫盘结果要输出的路径') 
    parser.add_argument('--list', '-l', dest="list", metavar='path_list', type=str, required=True,
        help='输入的要扫的目录的列表文件')
    parser.add_argument('--out', '-o', des='out', metavar='config.yml', type=str, required=True,
        help='输出的config.yml文件')
    args = parser.parse_args()
    pipe_path = args.pipe
    work_path = args.work
    input_list = args.list
    user_dict = traverse_dir(input_list)
    _dict = {}
    _dict["workdir"] = work_path
    _dict["pipe_path"] = pipe_path
    _dict["targetDir"] = user_dict
    with open(args.out, "w", encoding='utf-8') as outf:
        yaml.dump(data=_dict, stream=outf, default_flow_style=False, sort_keys=False, indent=4)

if __name__ == "__main__":
    main()