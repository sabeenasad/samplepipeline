#!/usr/bin/env nextflow
 
 /* 
 Performing quality control by Fastqc
*/

process quality_control {

    input:
    path fastq_path

    output:
    path "*_fastqc.zip"
    path "*_fastqc.html"
 
    """
    fastqc $fastq_path 
    """
}

/*
Adapter removal of fastq file
 */

  process cut_adapters {
 
    input:
    tuple path (fastq_path), val (adapter), val (quality)
    
    output:
    path 'adaptersremoved.fastq'
 
    """
    cutadapt -a $adapter  -q $quality -o adaptersremoved.fastq $fastq_path
 
    """
}

/*
Sed correction of fastq file generated from process cutting
*/

 process sed_correction {

   input:
   path sed_input
  
   output:
   path 'sed.fix'

   script:
   """
   sed -E 's/^((@|\\+)SRR[^.]+\\.[^.]+)\\.(1|2)/\\1/' $sed_input  > sed.fix
   """
}

/*
Alignment by bwa
*/

process align {

   input:
   val bwa_path
   val hg19_index_file
   path bwa_input
  
   output:
   path 'aligned.txt.bwa'

   """
   $bwa_path aln $hg19_index_file $bwa_input > aligned.txt.bwa
   
   """
}

/*
Generating sam file
*/

process generate_sam {

   input:
   val bwa_path
   val hg19_index_file
   path bwa_txt
   path bwa_input

  
   output:
   path 'generated.sam'

   """
   $bwa_path samse $hg19_index_file $bwa_txt $bwa_input  > generated.sam
   """
}

/*
Converting sam into bam
*/

process convert_sam {

   input:
   path New_sam

  
   output:
   path "New.bam"

   """
   samtools view -S -b $New_sam > New.bam
   """
}

/*
ToDo : Validate bam file for Errors
Add detection of errors in bam file and fix them according to GATK commands.
For example CleanSam. 
*/
/*
process validate_bam {

   input:
   val gatk_path
   path New_bam
  
   output:
   stdout

   """
   $gatk_path ValidateSamFile  -I $New_bam -MODE SUMMARY
   """
}
*/
/*
Correcting invalid mapping quality error
*/

process CorrectByCleanSam {

   input:
   val gatk_path
   path New_bam
  
   output:
   path 'FixedClean_mate.bam'

   """
   $gatk_path CleanSam  -I $New_bam  -O FixedClean_mate.bam
   """
}

/*
Correcting missing read group error
*/

process Correct_By_AddOrReplace {

   input:
   val gatk_path
   val Fixed_clean

   output:
   path 'reads-with-RG.bam'

   """
   $gatk_path AddOrReplaceReadGroups  I= $Fixed_clean O= reads-with-RG.bam SORT_ORDER= coordinate  RGID= foo  RGLB= bar  RGPL= illumina RGPU= unit1 RGSM= Sample1 CREATE_INDEX= True
   """
}

/*
Validating final bam file
*/
/*
process validate_final_bam {

   input:
   val gatk_path
   val reads_with_RG
  
   output:
   path "Validated_final"

   """
   $gatk_path ValidateSamFile  -I $reads_with_RG -MODE SUMMARY 2> >(tee err) 1> >(tee out) | tee > validated_final
   """
}
/*

/*
Variant calling by gatk
*/

process callingVariant {

   input:
   val gatk_path
   val hg19Fa
   path reads_with_RG

  
   output:
   path 'variant_final.vcf'

   """
   $gatk_path HaplotypeCaller -create-output-variant-index false -R $hg19Fa -I $reads_with_RG -O variant_final.vcf
   
   """
}


workflow {
   // fastqc_zip, fastc_html = quality_control (params.fastq_path)
    cut_adp = cut_adapters ([ params.fastq_path , params.adapter, params.quality])
    sed = sed_correcting (cut_adp)
    bwa_algn = align ( params.bwa_path, params.hg19_index_file, sed)
    gen_sam = generate_sam (params.bwa_path, params.hg19_index_file, bwa_algn , sed)
    con_sam = convert_sam (gen_sam)
    /*
    ToDo :
    val_bam = validate_bam ( params.gatk_path, con_sam)
    */
    clean_sam = CorrectByCleanSam (params.gatk_path, con_sam)
    corrected_addorreplaced= Correct_By_AddOrReplace (params.gatk_path, clean_sam)
    final_vcf = callingVariant (params.gatk_path,params.hg19Fa, corrected_addorreplaced)

}

 workflow.onComplete {

    sendMail(to: 'drsabeenasad@gmail.com', subject: 'My pipeline execution', body: 'Workflow has been completed')

 }   

 workflow.onError {

    sendMail(to: 'drsabeenasad@gmail.com', subject: 'Error encountered', body: 'Some error has occured in the wokflow')

 }