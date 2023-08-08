include { MAKE_REFERENCE_INDEX   } from './make_ref_index'  // this is being called from subworkflows
include { ALIGN_READS_TO_REF     } from './align_reads_to_ref'
include { CALL_VARIANTS          } from './call_variants'
include { IQTREE2 as IQTREE2_SNP } from '../../modules/local/iqtree2'        
include { VCFTOTAB      } from '../../modules/local/vcftotab'                   
include { VCFTOSNPALN   } from '../../modules/local/vcftosnpaln'                
include { VARIANTREPORT } from '../../modules/local/variantreport'              

workflow VARIANT_CALLING_ANALYSIS {

    take:
    input // [val(meta), [file(fastq)], val(ref_meta), file(reference), val(group_meta)]
    ch_samplesheet // channel: path

    main:
    ch_versions = Channel.empty()

    MAKE_REFERENCE_INDEX ( input.map { it[2..3] }.unique() )
    ch_versions = ch_versions.mix(MAKE_REFERENCE_INDEX.out.versions) 

    input_with_indexes = input
        .map { [it[2], it[0], it[1], it[3], it[4]] } // [val(ref_meta), val(meta), [file(fastq)], file(reference), val(group_meta)]
        .combine(MAKE_REFERENCE_INDEX.out.samtools_fai, by: 0)              
        .combine(MAKE_REFERENCE_INDEX.out.bwa_index, by: 0)
        .combine(MAKE_REFERENCE_INDEX.out.picard_dict, by: 0)
        .map { [it[1], it[2], it[0], it[3], it[4], it[5], it[6], it[7]] } // [val(meta), [file(fastq)], val(ref_meta), file(reference), val(group_meta), fai, bwa, picard]     
    
    ALIGN_READS_TO_REF (
        input_with_indexes
            .map { it[0..3] + it[5..6] }
            .unique()
    )
    ch_versions = ch_versions.mix(ALIGN_READS_TO_REF.out.versions)       

    CALL_VARIANTS (
        input_with_indexes
            .map { [it[0], it[2], it[1]] + it[3..5] + [it[7]] } // [val(meta), val(ref_meta), [file(fastq)], file(reference), val(group_meta), fai, picard]
            .combine(ALIGN_READS_TO_REF.out.bam, by: 0..1)
            .combine(ALIGN_READS_TO_REF.out.bai, by: 0..1) // [val(meta), val(ref_meta), [file(fastq)], file(reference), val(group_meta), fai, picard, bam, bai]
            .map { [it[0], it[7], it[8], it[1]] + it[3..6] }
    )
    ch_versions = ch_versions.mix(CALL_VARIANTS.out.versions)       
   
    VCFTOTAB ( CALL_VARIANTS.out.vcf )                                                       
    ch_versions = ch_versions.mix(VCFTOTAB.out.versions.toSortedList().map{it[0]})
                                                                                
    VCFTOSNPALN ( VCFTOTAB.out.tab )                                            
    ch_versions = ch_versions.mix(VCFTOSNPALN.out.versions.toSortedList().map{it[0]})
                                                                                
    VARIANTREPORT ( VCFTOSNPALN.out.fasta, ch_samplesheet )                     
    ch_versions = ch_versions.mix(VARIANTREPORT.out.versions.toSortedList().map{it[0]})
    
    IQTREE2_SNP ( VCFTOSNPALN.out.fasta, [] ) 

    emit:
    picard_dict  = MAKE_REFERENCE_INDEX.out.picard_dict
    samtools_fai = MAKE_REFERENCE_INDEX.out.samtools_fai
    samtools_gzi = MAKE_REFERENCE_INDEX.out.samtools_gzi
    bwa_index    = MAKE_REFERENCE_INDEX.out.bwa_index 
    phylogeny    = IQTREE2_SNP.out.phylogeny                                        
                       .map { [it[0].group, it[0].ref, it[1]] }        // channel: [ group_meta, ref_meta, tree ]

    versions = ch_versions                           // channel: [ versions.yml ]

}

