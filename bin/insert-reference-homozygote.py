#!/usr/bin/env python
import os
import sys
import subprocess
import re

input_fname = sys.argv[1]
sites_fname = sys.argv[2]

gq_val = 0
if len(sys.argv) > 3:
    gq_val = int(sys.argv[3])

# Need the chromosome as an integer so as to know what comes after chromosome 22
# We are assuming the VCFs are in sorted order by chromosome number and that
# X comes after 22, Y comes after X, XY is pseudo-autosomal region and really X
# and MT is last. It is not clear however what sorted order is considered to be
# for VCF for these chromosomes which may be named by string rather than an integer
# Certainly not clear is whether we should treat XY as separate chromosome if it
# is used, or as chromosome X, and whether XY would be interspersed by X position
# with the X chromosome. To be investigated...
def parse_pos(chm_s, pos_s):
    chm = None
    try:
        chm = int(chm_s)
    except:
        if   chm_s == "X":  chm = 23
        elif chm_s == "Y":  chm = 24
        elif chm_s == "XY": chm = 23
        elif chm_s == "MT": chm = 26        
        else: chm = 100

    return (chm_s, chm, int(pos_s))

# Output a record with all genotypes set to homozygous reference for a site that
# was not found in the input VCF.
def insert_site(site, gq_val, n_samples):
    print '\t'.join(site.strip('\r\n').split('\t',8)[0:8]),
    sys.stdout.softspace=False
    print '\tGT',
    sys.stdout.softspace=False
    if gq_val > 0:
        print ':GQ',
        sys.stdout.softspace=False
        print ('\t0|0:%d' % gq_val) * n_samples
    else:
        print '\t0|0' * n_samples


# ======== Main program ========

# Skip through sites file header
# NOTE: should parse for contig lines and potentially add them if they are not in the input VCF
#
# Using bcftools to read file so that file may be BCF or VCF, and gzip compressed or not, and
# we get it as uncompressed VCF here
p_sfh = subprocess.Popen(['bcftools','view','-G','-m2','-M2','-v','snps',sites_fname], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
sites_fh = p_sfh.stdout
sites_headers = {}
info_p = re.compile("##INFO=")
while True:
    line = sites_fh.readline()
    if line[0:6] == '#CHROM': break;
    if info_p.match(line):
        sites_headers[line] = 1
        
# Burn through header of input, but copy to output this time, adding INFO lines from the sites
# file header if we need to, otherwise we get complaints from bcftools on the output VCF
n_samples = 0
p_ifh = subprocess.Popen(['bcftools','view','-m2','-M2','-v','snps',input_fname], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
input_fh = p_ifh.stdout
contig_p = re.compile('^##contig=<ID=([^,>]+)')
contigs = {}
while True:
    line = input_fh.readline()
    m = contig_p.match(line)
    if m: contigs[m.group(1)] = 1
    if line in sites_headers: del sites_headers[line]
    if line[0:6] == '#CHROM':
        n_samples = len(line.split("\t")) - 9
        for missing_header in sites_headers:
            print missing_header,
        print line,
        break;
    print line,

# Loop through the files, copying input VCF to output, and inserting records
# with all genotypes set to homozygous reference where records are found in
# the sites file but not in the input VCF
input_line = input_fh.readline()
sites_line = sites_fh.readline()
while input_line != "" and sites_line != "":
    (input_chm_name, input_chm, input_pos) = parse_pos(*input_line.split('\t',2)[0:2])
    (sites_chm_name, sites_chm, sites_pos) = parse_pos(*sites_line.split('\t',2)[0:2])

    # We have a site in the input that is not in the sites file, pass through to output
    while input_chm < sites_chm or (input_chm == sites_chm and input_pos < sites_pos):
        print input_line,
        input_line = input_fh.readline()
        if input_line == "": break;
        (input_chm_name, input_chm, input_pos) = parse_pos(*input_line.split('\t',2)[0:2])

    # A site defined in the sites VCF file that is not in the input VCF. Add the site
    # to the output with homozygous reference genotypes
    while sites_chm < input_chm or (input_chm == sites_chm and sites_pos < input_pos):
        if sites_chm_name in contigs: insert_site(sites_line, gq_val, n_samples)
        sites_line = sites_fh.readline()
        if sites_line == "": break;
        (sites_chm_name, sites_chm, sites_pos) = parse_pos(*sites_line.split('\t',2)[0:2])

    # Site defined in both, pass the input through and read new records from each
    if sites_chm == input_chm and sites_pos == input_pos:
        print input_line,
        input_line = input_fh.readline()
        sites_line = sites_fh.readline()

# Finish off which ever file was longer - at least one of input_line or sites_line
# must be empty string to exit above loop
while input_line != "":
    print input_line,
    input_line = input_fh.readline()

while sites_line != "":
    (sites_chm_name, sites_chm, sites_pos) = parse_pos(*sites_line.split('\t',2)[0:2])
    if sites_chm_name in contigs: insert_site(sites_line, gq_val, n_samples)
    sites_line = sites_fh.readline()

input_fh.close()
sites_fh.close()
