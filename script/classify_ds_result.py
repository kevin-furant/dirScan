#! /usr/bin/env python
import sys, os
import pandas as pd
from pathlib import Path
import re
from tabulate import tabulate

def get_disk_info(x, _dict):
    prefix = "/".join(x.split("/", 4)[:4])
    return _dict.get(prefix, "")

def get_size(x):
    bracket_pattern = r'\((\d+)\)'
    number_pattern = r'^\d+'
    bracket_match = re.search(bracket_pattern, x)
    if bracket_match:
        return int(bracket_match.group(1))
    number_match = re.search(number_pattern, x)
    if number_match:
        return int(number_match.group())
    return 0

def main():
    user_name = sys.argv[1]
    input_merge_ds_tsv = sys.argv[2]
    output_dir = sys.argv[3]
    disk_prefix = [
        "/public/work/Personal",
        "/public/work/Project",
        "/public2/work/Project",
        "/public3/work/Project",
        "/public4/data4/Project",
    ]

    disk_names = [
        # "disk_1", "disk_2", "disk_3", "disk_4", "disk_5"
        "public_Personal", "public_Project", "public2_Project", "public3_Project", "public4_Project"
    ]

    disk_dict = dict(zip(disk_prefix, disk_names))
    df = pd.read_csv(input_merge_ds_tsv, sep="\t", header=None, names=["Path", "Size", "Seconds", "Days"])
    output_path = Path(output_dir)
    if not output_path.exists():
        output_path.mkdir(mode=0o755, parents=True, exist_ok=True)
    df["Path"] = df["Path"].replace('"', '')
    df["disk"] = df["Path"].map(lambda x: get_disk_info(x, disk_dict))
    df["Byte"] = df["Size"].map(get_size)

    grouped = df.groupby("disk")
    result_dict = {}
    for each in disk_names:
        try:
            _df = grouped.get_group(each)
        except KeyError as err:
            _df = pd.DataFrame()
        if not _df.empty:
            byte_total_size = _df["Byte"].sum()/(1024**3)
            result_dict[each] = byte_total_size
        else:
            result_dict[each] = 0
    user_out_df = pd.Series(result_dict, name=user_name).to_frame().T
    formatted_table = tabulate(
        user_out_df,
        headers="keys",
        tablefmt="tsv",
        stralign="left",
        numalign="left"
    )
    out_stat_result = output_path / (user_name + ".disk_category.tsv")
    # user_out_df.to_csv(out_stat_result, sep="\t")
    with open(out_stat_result, "w", encoding="utf-8") as f:
        f.write(formatted_table)

if __name__ == "__main__":
    main()