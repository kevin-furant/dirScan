from snakemake.utils import min_version
from pathlib import Path
from datetime import datetime

min_version("8.15.0")
configfile: "/public/work/Personal/fuxiangke/pipeline/userDirScanner/config.yml"

onstart:
    print("workflow is begining!")
onsuccess:
    print("workflow finished, no error!")
onerror:
    print("An error occured, check please!")

current_date = datetime.now().strftime('%Y-%m-%d')
def get_output_files():
    output_files = []
    for user, paths, in config["targetDir"].items():
        for i , path in enumerate(paths):
            subdir = Path(path).name
            output_files.append(f"{config["workdir"]}/{current_date}/{user}/{subdir}_{i+1}.ds.tsv")
    return output_files

include: Path(config["pipe_path"]) / "rules" / "prepare.smk"  
rule all:
    input:
        get_output_files(),
        expand("{workdir}/{current_date}/{user}/report.md", workdir=config["workdir"], current_date=current_date, user=config["targetDir"].keys())
