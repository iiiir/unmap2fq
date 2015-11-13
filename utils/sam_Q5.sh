#!/bin/bash

[[ $# -lt 1 ]] && echo "$0 <in.bam>" && exit 0

bam=$1; shift
[[ ! -f "$bam" ]] && echo ">>> not exist: $bam" && exit 1
[[ $# -gt 0 ]] && QSCORE=$1 || QSCORE=5
Qbam=${bam/.bam/.Q$QSCORE.bam}

cmd="samtools view -h -b -q $QSCORE $bam -o $Qbam"
eval $cmd
