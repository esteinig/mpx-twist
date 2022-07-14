process MinimapRetain {

    tag { "$id : $idx_name" }
    label "minimap2"

    publishDir "$params.outdir/$params.stage/$params.subdir", mode: "symlink", pattern: "${id}_${idx_name}.paf"

    input:
    tuple val(id), file(forward), file(reverse)
    file(index)

    output:
    tuple val(id), file("${id}_${idx_name}.R1.fastq"), file("${id}_${idx_name}.R2.fastq")

    script:

    idx_name = index.baseName

    """
    minimap2 -t $task.cpus -ax sr ${index} $forward $reverse | samtools fastq --R1 ${id}_${idx_name}.R1.fastq --R2 ${id}_${idx_name}.R2.fastq XXX
    """

}
