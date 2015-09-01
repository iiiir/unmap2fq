#!/bin/env python
import sys
import os
import argparse
import subprocess
import sjm
import util

# default: write final bam and fastq in current folder
# will sort by query name and pipe to bamtofastq

p = argparse.ArgumentParser(description='Generating the job file for the getting unmapped reads from bam file and revert to fastq')
p.add_argument('-b','--bam', metavar='STR', required=True, help='Support for aligned and dedupped BAMs as input')
p.add_argument('-j', '--jobfile', metavar='FILE', help='The jobfile name (default: stdout)')
p.add_argument('-o', '--output', metavar='DIR', required=True, help='PREFIX of the output file')
p.add_argument('-A','--account', metavar='STR', help='Support for aligned and dedupped BAMs as input')
p.add_argument('-T', '--tmp', metavar='DIR', required=True, help='The TMP directory for storing intermediate files (default=output directory')
p.add_argument('--submit', action='store_true', help='Submit the jobs')
args = p.parse_args()

assert os.path.isfile(args.bam), "Error! %s does not exist!" % args.bam

if args.jobfile is None:
    jobfile=None
else:
    jobfile=util.File(args.jobfile)

# set up directory
tmpdir=os.getcwd()
if args.tmp: tmpdir=util.Dir(args.tmp)
tmpdir.mkdirs()

sjm.Job.name_prefix="UNMAP"+"."
sjm.Job.memory="5G" # default if not provided
sjm.Job.queue="pcgp"
sjm.Job.project="CompBio"
if args.account: sjm.Job.sge_options="-A %s" % args.account
tmpdir = getattr(__builtins__, 'str')(tmpdir)

def get_unmap(bamfile):
    jobs=[]
    job1 = sjm.Job('get_unmap_f48-%s'%bamfile.prefix)
    job1.memory = "5G"
    job1.output = os.path.join(tmpdir, '%s.%s' % (bamfile.prefix, 'f48.bam'))
    job1.append('samtools view -h -F 4 -f 8 %s -bo %s'%(bamfile.path,job1.output))
    jobs.append(job1)
    job2 = sjm.Job('get_unmap_f84-%s'%bamfile.prefix)
    job2.output = os.path.join(tmpdir, '%s.%s' % (bamfile.prefix, 'f84.bam'))
    job2.append('samtools view -h -F 8 -f 4 %s -bo %s'%(bamfile.path,job2.output))
    jobs.append(job2)
    job3 = sjm.Job('get_unmap_f12-%s'%bamfile.prefix)
    job3.output = os.path.join(tmpdir, '%s.%s' % (bamfile.prefix, 'f12.bam'))
    job3.append('samtools view -h -f 12 %s -bo %s'%(bamfile.path,job3.output))
    jobs.append(job3)
    return jobs

def merge_bams(pjobs):
    bams = [pjob.output for pjob in pjobs]
    job = sjm.Job('merge_bams-%s'%(bamfile.prefix))
    job.memory = "5G"
    job.output = args.output + '.unmapped.bam'
    job.append('samtools merge %s %s'%(job.output, ' '.join(bams)))
    job.depend(*pjobs)
    return job
        
def bam2fastq(pjob):
    unmapped_bamfile = util.File(pjob.output)
    job = sjm.Job('bam2fq-%s'%(bamfile.prefix))
    job.memory = "10G"
    job.output = args.output
    job.append('bam2fq.sh -o %s %s'%(job.output, unmapped_bamfile.path))
    job.depend(pjob)
    return job

bamfile=util.File(args.bam)

# get unmapped reads, pair end
jobs = get_unmap(bamfile)

# merge bams
job = merge_bams(jobs)

# revert bam to fastq
job = bam2fastq(job)

descout = sys.stdout if jobfile is None else open(jobfile.path, "w")
descout.write(sjm.Job().depend(job).desc())
descout.flush()

if args.submit:
    print >> sys.stderr, "Submitting jobs (%s) through SJM" % jobfile
    os.system("sjm %s &" %jobfile)
