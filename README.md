# unmap2fq
Short pipeline that abstract unmapped reads from a bam file and convert to fastq files (PE reads)


### dependencies    
python 2.7    
SJM (simple job manager)    
samtools    
picard     
bedtools    
LSF batch system (or other)    

### usage    
To creat job file: run_unmap.py --bam NA12878.bam --out NA12878_test --tmp unmap_test -j na12878.sjm    
To run job file  : sjm na12878.sjm    
