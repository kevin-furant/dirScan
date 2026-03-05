import os
from pathlib import Path
#from datetime import datetime

configfile: "/public/work/Personal/fuxiangke/pipeline/userDirScanner/config.yml"
#current_date = datetime.now().strftime('%Y-%m-%d')

def get_last_part(path):
    return os.path.basename(path)

def get_subdirs(user):
    paths = config["targetDir"][user]
    subdirs = []
    for i, path in enumerate(paths):
        subdirs.append((Path(path).name, i+1))
    return subdirs

def generate_input_files(wildcards):
    user = wildcards.user
    current_date = wildcards.current_date
    subdirs = [subdir for subdir, _ in get_subdirs(user)]
    indices = [index for _, index in get_subdirs(user)]
    l = len(indices)
    return {
        "ds_tsv": expand("{workdir}/{current_date}/{user}/{subdir}_{index}.ds.tsv", zip, workdir=[config["workdir"]] * l, current_date=[current_date] * l, user=[user] * l, subdir=subdirs, index=indices),
        "ds_permission_tsv": expand("{workdir}/{current_date}/{user}/{subdir}_{index}.ds.permission_denied.tsv", zip, workdir=[config["workdir"]] * l, current_date=[current_date] * l, user=[user] * l, subdir=subdirs, index=indices)
    }
 
rule createDirAndFiles:
    output:
        "{workdir}/{current_date}/{user}/{subdir}_{index}.tsv"
    params:
        workdir = config["workdir"],
        user = lambda wildcards: wildcards.user,
        subdir = lambda wildcards: wildcards.subdir,
        index = lambda wildcards: wildcards.index, 
        #path = lambda wildcards: next(path for path in config["targetDir"][wildcards.user] if get_last_part(path) == wildcards.subdir)
        path = lambda wildcards: config["targetDir"][wildcards.user][int(wildcards.index) - 1]
    wildcard_constraints:
        index = "[0-9]+"
    shell:
        """
        mkdir -p {params.workdir}/{current_date}/{params.user}
        echo {params.path} > {output}
        """

rule dirScanner:
    input:
        "{workdir}/{current_date}/{user}/{subdir}_{index}.tsv"
    output:
        "{workdir}/{current_date}/{user}/{subdir}_{index}.ds.tsv",
        "{workdir}/{current_date}/{user}/{subdir}_{index}.ds.permission_denied.tsv"	
    wildcard_constraints:
        index = "[0-9]+"
    params:
        workdir = config["workdir"],
        scanner = Path(config["pipe_path"]) / "script" / "userDirScanner" / "userDirScanner"
    shell:
        """
        path=$(cat {input} | tr '\n' ' ')
        {params.scanner} $path {output}
        """

rule resultStat:
    input:
        unpack(lambda wildcards: generate_input_files(wildcards))
    output:
        merge_ds = "{workdir}/{current_date}/{user}/merge.ds.tsv",
        vcf_tsv = "{workdir}/{current_date}/{user}/vcf.tsv",
        fq_tsv = "{workdir}/{current_date}/{user}/fastq.tsv",
        bam_tsv = "{workdir}/{current_date}/{user}/bam.tsv",
        report_md = "{workdir}/{current_date}/{user}/report.md"
    params:
        workdir = config["workdir"],
        user = lambda wildcards: wildcards.user,
        current_date = lambda wildcards: wildcards.current_date,
        retstat = Path(config["pipe_path"]) / "script" / "dirScanResultStat.pl"
    shell:
        """
        cat {input.ds_tsv} > {params.workdir}/{params.current_date}/{params.user}/merge.ds.tsv
        cat {input.ds_permission_tsv} > {params.workdir}/{params.current_date}/{params.user}/merge.permission.tsv
        perl {params.retstat} {wildcards.user} {params.workdir}/{params.current_date}/{params.user}/merge.ds.tsv 365
        """
