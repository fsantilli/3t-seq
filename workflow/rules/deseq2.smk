rule subset_gtf:
    input:
        gtf_path,
    output:
        rdata_folder.joinpath("deseq2/ann.rds"),
    conda:
        "../env/R.yml"
    threads: 1
    resources:
        runtime=60,
        mem_mb=20000,
    log:
        log_folder.joinpath("R/subset_gtf.log"),
    script:
        "../scripts/subset_gtf_v1.R"


rule deseq2:
    input:
        unpack(get_deseq2_inputs),
    output:
        deg_table=tables_folder.joinpath("deseq2/{serie}/results.csv"),
        deg_table_shrink=tables_folder.joinpath("deseq2/{serie}/results.shrink.csv"),
        dds=rdata_folder.joinpath("deseq2/{serie}/dds.rds"),
    params:
        # quantile_threshold=0.25,
        annotation_type=config["genome"]["annotation_type"],
        test=lambda wildcards: get_deseq2_test(wildcards),
        variable=lambda wildcards: get_deseq2_variable(wildcards),
        reference_level=lambda wildcards: get_deseq2_reference_level(wildcards),
    threads: 4
    resources:
        runtime=40,
        mem_mb=20000,
    conda:
        "../env/R.yml"
    log:
        log_folder.joinpath("R/{serie}/deseq2.log"),
    script:
        "../scripts/deseq2_v1.R"


localrules:
    yte_single_copy_genes,
    datavzrd_single_copy_genes,


rule yte_single_copy_genes:
    input:
        datasets=[
            tables_folder.joinpath("deseq2/{serie}/results.csv"),
            tables_folder.joinpath("deseq2/{serie}/results.shrink.csv"),
        ],
    output:
        analysis_folder.joinpath("datavzrd", "{serie}", "datavzrd.yaml"),
    params:
        template=Path(workflow.basedir) / "datavzrd/deg-plots-template.yaml",
        plot_name="Single copy genes DESeq2",
        view_specs=[str(Path(workflow.basedir) / "datavzrd/volcano-ma-plot.json")],
    conda:
        "../env/yte.yml"
    log:
        log_folder.joinpath("{serie}/yte.log"),
    threads: 1
    script:
        "../scripts/yte.py"


rule datavzrd_single_copy_genes:
    input:
        config=analysis_folder.joinpath("datavzrd", "{serie}", "datavzrd.yaml"),
        dataset=tables_folder.joinpath("deseq2/{serie}/results.csv"),
        dataset_shrink=tables_folder.joinpath("deseq2/{serie}/results.shrink.csv"),
    output:
        report(
            directory(analysis_folder.joinpath("datavzrd", "{serie}", "datavzrd")),
            category="Single copy genes",
            subcategory="Differential expression",
            labels={"serie": "{serie}", "figure": "DESeq2 analysis"},
            htmlindex="index.html",
        ),
    log:
        log_folder.joinpath("{serie}/datavzrd.log"),
    wrapper:
        "v2.6.0/utils/datavzrd"
