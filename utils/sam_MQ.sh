#!/bin/bash

[[ $# -lt 1 ]] && echo "$0 <in.bam>" && exit 0

bam=$1
[[ ! -f "$bam" ]] && echo ">>> not exist: $bam" && exit 1

o=${bam/.bam/.counts.tsv}
samtools view -q 0 $bam | \
	awk '{print $5}' | \
		sort | \
			uniq -c | \
				awk '{print $2"\t"$1}' | \
					sort -k1n > $o
