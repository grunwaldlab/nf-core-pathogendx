process GATK4_VARIANTFILTRATION {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::gatk4=4.3.0.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gatk4:4.3.0.0--py36hdfd78af_0':
        'quay.io/biocontainers/gatk4:4.3.0.0--py36hdfd78af_0' }"

    input:
    tuple val(meta), path(vcf), path(tbi)
    path  fasta
    path  fai
    path  dict
    path  gzi // only needed if reference is gzipped

    output:
    tuple val(meta), path("*.vcf.gz"), emit: vcf
    tuple val(meta), path("*.tbi")   , emit: tbi
    path "versions.yml"		         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    // Infer .dict file name that gatk expects, even if ends in .fasta.gz
    def dict_name = fasta.getBaseName()
    if (dict_name ==~ /^.*\.(fasta|fna|fa)$/) {
        dict_name = dict_name.replaceAll(/\.(fasta|fna|fa)$/, "")
    }
    dict_name = "${dict_name}.dict"
    
    def avail_mem = 3
    if (!task.memory) {
        log.info '[GATK VariantFiltration] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.toGiga()
    }
    """
    # Make sure the .dict file is named correctly
    if [[ $dict_name != $dict ]]; then
        ln -s $dict $dict_name
    fi

    gatk --java-options "-Xmx${avail_mem}G" VariantFiltration \\
        --variant $vcf \\
        --output ${prefix}.vcf.gz \\
        --reference $fasta \\
        --tmp-dir . \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf.gz
    touch ${prefix}.vcf.gz.tbi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gatk4: \$(echo \$(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*\$//')
    END_VERSIONS
    """
}
