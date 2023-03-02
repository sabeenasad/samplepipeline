The script is written to analyze single end Fastq files and to generate the final Variant calling file (vcf.) The script is suitable for fastq files generated with different platforms.

# Prerequisites for the pipeline
For running this pipeline some prerequisites are needed.
Nextflow version 22.04.3 build 5703
Gatk version 4.1.9.0
Bwa version 0.7.17
hg19 index file
hg19.fa file
(Index file can be downloaded by using the following commands.
Index file formation is only done one time).

wget http://hgdownload.cse.ucsc.edu/goldenPath/hg19/bigZips/chromFa.tar.gz
tar zvfx chromFa.tar.gz cat *.fa > wg.fa
cat *.fa > wg.fa
rm chr*.fa

# Samplescript.config file:
samplescript.config file contains all the variables defined to be used in the script.
samplescript.config file variables must be set up by the user, according to the path the files are stored in their own local machine. 
fastq_path = "Enterpath of fastq file to be analyzed”
adapter = "Adapter sequence"
quality = Minimum threshold quality score
gatk_path = "Enterpath/gatk"
bwa_path = "Enterpath/bwa"
hg19_index_file = "Enterpath/hg19_index_file"
hg19Fa = "Enterpath/hg19.fa"

# Configuration for mail server for sending notification
Currently the set up file has been set up for gmail.
For setting up username and password for the server use the following commands from the terminal.

nextflow secrets set EMAIL_ADDRESS "XYZ@gmail.com"
nextflow secrets set PASSWORD "XYZ"

Note: In this script validation has not been done.

The fastq files and the intermediate files generated are large files, so the user must ensure they have enough storage memory in their machines.

 








