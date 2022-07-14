#!/usr/bin/env nextflow


/* 
vim: syntax=groovy
-*- mode: groovy;-*-

Monkeypox assembly workflow

@authors: Eike Steinig, Mona Taouk

*/

nextflow.enable.dsl=2

// Change comment

// Basic workflow using alignment against Monkeypox reference
// and subsequent assembly of mapped reads

include { check_file } from './modules/utils'

include { Fastp } from './modules/fastp' addParams(
    stage: "quality_control",
    subdir: ""

)
include { Spades as ReferenceAssembly } from './modules/spades' addParams(
    stage: "reference_assembly",
    subdir: "assembly"
)
include { MinimapRetain } from './modules/samtools' addParams(
    stage: "reference_assembly",
    subdir: "mapped_reads"
)

// Aligns reads to outbreak reference and assembles aligned reads
workflow reference_assembly {
    take:
        reads
        reference
    main:
        qc_reads = Fastp(reads)
        extracted_reads = MinimapRetain(qc_reads[0], reference)
        assembly = ReferenceAssembly(extracted_reads)
    emit:
        assembly[0]
        assembly[1]
}

include { MinimapAlignCigarPAF as MinimapHostAlignment } from './modules/minimap2' addParams(
    stage: "denovo_assembly",
    subdir: "host_alignments"
)
include { DepleteAligned } from './modules/mgp_tools' addParams(
    stage: "denovo_assembly",
    subdir: "host_depletion",
    extract_min_len: params.host_deplete_min_qaln_len,
    extract_min_mapq: params.host_deplete_min_mapq
)
include { Spades as DenovoAssembly } from './modules/spades' addParams(
    stage: "denovo_assembly",
    subdir: "assembly"
)

// Depletes human reads and assembles remainign reads
workflow denovo_assembly {
    take:
        reads
        host_index
    main:
        qc_reads = Fastp(reads)
        host_aligned_reads = MinimapHostAlignment(qc_reads[0], host_index)
        depleted_reads = DepleteAligned(host_aligned_reads[0], host_aligned_reads[1])
        assembly = DenovoAssembly(depleted_reads[0]) 
    emit:
        assembly[0]
        assembly[1]
}

workflow {

    reads = channel.fromFilePairs(params.fastq, flat: true)

    // Reference alignment and assembly of aligned reads
    if (params.reference_assembly){
        reference = check_file(params.reference)
        reference_assembly(reads, reference)
    }
    // De novo assembly of host depleted reads
    if (params.denovo_assembly){
        host_index = check_file(params.host_index)
        denovo_assembly(reads, host_index)
    }

}

