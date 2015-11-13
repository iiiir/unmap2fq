#!/bin/bash

# revert bam to fastq
# -r for bam files that are recalibrated

inbam=
opre=
recal_bam=

while getopts "o:r" opt; do
	case $opt in
		o)	opre=$OPTARG;
			;;
		r)	recal_bam=true;
			;;
		?)	echo "Unrecognized!";
			exit 1;
			;;
	esac
done
shift $((OPTIND -1))
inbam=("$@")
[[ -z "$inbam" || -z "$opre" ]] && echo "$0 <-o outname_R1.fastq> [-r relcal] <1.bam ... >" && exit 0
bam_counts=${#inbam[@]}

if [[ $recal_bam && $bam_counts -eq 1 ]]; then
	>&2 echo ">>> Single GATK recalibrated BAM --> FASTQ"
	sleep 2
	cmd="java -Xms5g -Xmx5g -jar $PICARDPATH/picard.jar RevertSam\
		TMP_DIR=$JAVATMP \
		INPUT=$inbam \
		OUTPUT=/dev/stdout \
		SORT_ORDER=queryname \
		COMPRESSION_LEVEL=0 \
		VALIDATION_STRINGENCY=SILENT | \
	bedtools bamtofastq -i /dev/stdin -fq ${opre}_R1.fastq -fq2 ${opre}_R2.fastq"
	>&2 echo ">>> Your command:" $cmd
	eval $cmd
elif [[ ! $recal_bam && $bam_counts -gt 1 ]]; then
	>&2 echo ">>> Multiple regular BAMs --> FASTQ..."
	sleep 2
	infiles=
	for bam in ${inbam[@]}; do infiles="$infiles INPUT=$bam"; done
	cmd="java -Xms5g -Xmx5g -jar $PICARDPATH/picard.jar MergeSamFiles \
		TMP_DIR=$JAVATMP \
		$infiles \
		OUTPUT=/dev/stdout \
		SORT_ORDER=queryname \
		MERGE_SEQUENCE_DICTIONARIES=true \
		COMPRESSION_LEVEL=0 \
		VALIDATION_STRINGENCY=SILENT | \
	bedtools bamtofastq -i /dev/stdin -fq ${opre}_R1.fastq -fq2 ${opre}_R2.fastq"
	>&2 echo ">>> Your command:" $cmd
	eval $cmd
elif [[ $recal_bam && $bam_counts -gt 1 ]]; then
	>&2 echo ">>> Multiple recalibrated BAMs --> FASTQ..."
	sleep 2
	infiles=
	for bam in ${inbam[@]}; do infiles="$infiles INPUT=$bam"; done
	cmd="java -Xms5g -Xmx5g -jar $PICARDPATH/picard.jar MergeSamFiles \
		TMP_DIR=$JAVATMP \
		$infiles \
		OUTPUT=/dev/stdout \
		SORT_ORDER=queryname \
		MERGE_SEQUENCE_DICTIONARIES=true \
		COMPRESSION_LEVEL=0 \
		VALIDATION_STRINGENCY=SILENT | \
	java -Xms5g -Xmx5g -jar $PICARDPATH/picard.jar RevertSam\
		TMP_DIR=$JAVATMP \
		INPUT=/dev/stdin \
		OUTPUT=/dev/stdout \
		SORT_ORDER=queryname \
		COMPRESSION_LEVEL=0 \
		VALIDATION_STRINGENCY=SILENT | \
	bedtools bamtofastq -i /dev/stdin -fq ${opre}_R1.fastq -fq2 ${opre}_R2.fastq"
	>&2 echo ">>> Your command:" $cmd
	eval $cmd
else
	>&2 echo ">>> Single regular BAM --> FASTQ"
	sleep 2
	cmd="java -Xms5g -Xmx5g -jar $PICARDPATH/picard.jar SortSam \
		TMP_DIR=$JAVATMP \
		INPUT=$inbam \
        OUTPUT=/dev/stdout \
        SORT_ORDER=queryname \
        COMPRESSION_LEVEL=0 \
        VALIDATION_STRINGENCY=SILENT | \
	bedtools bamtofastq -i /dev/stdin -fq ${opre}_R1.fastq -fq2 ${opre}_R2.fastq"
	>&2 echo ">>> Your command:" $cmd
	eval $cmd
fi
