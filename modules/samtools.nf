process MinimapRetain {

    tag { "$id : $idx_name" }
    label "minimap2"

    publishDir "$params.outdir/$params.stage/$params.subdir", mode: "symlink", pattern: file("${id}_${idx_name}.R1.fastq.gz"), file("${id}_${idx_name}.R2.fastq.gz")

    input:
    tuple val(id), file(forward), file(reverse)
    file(index)

    output:
    tuple val(id), file("${id}_${idx_name}.R1.fastq.gz"), file("${id}_${idx_name}.R2.fastq.gz")

    script:

    idx_name = index.baseName

    """
    minimap2 -t $task.cpus -ax sr ${index} $forward $reverse | samtools fastq -1 ${id}_${idx_name}.R1.fastq.gz -2 ${id}_${idx_name}.R2.fastq.gz -f 2 -
    """

}
