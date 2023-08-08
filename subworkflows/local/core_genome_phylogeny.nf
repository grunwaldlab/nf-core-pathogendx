include { PIRATE                    } from '../../modules/nf-core/pirate/main'
include { SAMTOOLS_FAIDX            } from '../../modules/nf-core/samtools/faidx/main'
include { MAFFT as MAFFT_SMALL      } from '../../modules/nf-core/mafft/main'
include { IQTREE2                   } from '../../modules/local/iqtree2'
include { REFORMATPIRATERESULTS     } from '../../modules/local/reformat_pirate_results'
include { ALIGNFEATURESEQUENCES     } from '../../modules/local/align_feature_sequences'
include { SUBSETCOREGENES           } from '../../modules/local/subset_core_genes'
include { RENAMECOREGENEHEADERS     } from '../../modules/local/rename_core_gene_headers'
include { COREGENOMEPHYLOGENYREPORT } from '../../modules/local/core_gene_phylogeny_report'

workflow CORE_GENOME_PHYLOGENY {

    take:
    sample_gff // [ val(meta), file(sample_gffs), val(group_meta), [file(ref_gffs)] ]
    ch_samplesheet // channel: path

    main:

    ch_versions = Channel.empty()

    // group samples by reference genome                                        
    ch_gff_grouped = sample_gff                                                  
        .groupTuple(by: 2)                                                      
        .map { [it[2], it[1] + it[3].flatten().unique()] } // [ val(group_meta), [ gff ] ]

    PIRATE ( ch_gff_grouped )
    ch_versions = ch_versions.mix(PIRATE.out.versions.first())

    REFORMATPIRATERESULTS ( PIRATE.out.results )                                                   
    ch_versions = ch_versions.mix(REFORMATPIRATERESULTS.out.versions.first())                  
    
    // Extract sequences of all genes (does not align, contrary to current name)
    ALIGNFEATURESEQUENCES ( PIRATE.out.results )                            
    ch_versions = ch_versions.mix(ALIGNFEATURESEQUENCES.out.versions.first())

    // Rename FASTA file headers to start with just sample ID for use with IQTREE
    RENAMECOREGENEHEADERS ( ALIGNFEATURESEQUENCES.out.feat_seqs )
    
    // Filter for core single copy genes with no paralogs
    SUBSETCOREGENES ( REFORMATPIRATERESULTS.out.gene_fam.join(RENAMECOREGENEHEADERS.out.feat_seqs) )

    // Align each gene family with mafft
    MAFFT_SMALL ( SUBSETCOREGENES.out.feat_seq.transpose(), [] )
    ch_versions = ch_versions.mix(MAFFT_SMALL.out.versions.first())

    // Inferr phylogenetic tree from aligned core genes
    IQTREE2 ( MAFFT_SMALL.out.fas.groupTuple(), [] )
    ch_versions = ch_versions.mix(IQTREE2.out.versions.first())

    // Make report
    COREGENOMEPHYLOGENYREPORT ( IQTREE2.out.phylogeny, ch_samplesheet )                           

    emit:
    pirate_aln      = PIRATE.out.aln        // channel: [ ref_meta, align_fasta ]
    phylogeny       = IQTREE2.out.phylogeny // channel: [ group_meta, tree ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

