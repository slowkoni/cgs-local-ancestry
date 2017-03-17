#!/usr/bin/perl -w -I .
use strict;
use cmdline_args;

if (!$ARGV[0] || $ARGV[0] eq "help") {
  print STDERR <<EOF;

  Script to execute combined phasing (optional) and rfmix v2.X local ancestry
  analysis on any supplied VCF/BCF file.

  Usage: --vcf <input VCF/BCF file> [ --ref <reference prefix/basename> ] [ --no-phasing ] [ --assume-reference ]   
         [ --fill-missing ]

  Performs phasing and local ancestry analysis using 1000 genomes phase 3
  genotypes as reference (built in), reduced to bi-allelic SNPs only which
  have a minimum minor allele count of 20.

  --ref: OPTIONAL. Use this to override the internal 1KG 5 subpopulation reference panel
         prefix path to reference data VCF or BCF file and corresponding map file.
         This program will look for <reference prefix>.{vcf,vcf.gz,bcf,bcf.gz} and
         <reference prefix>.map

  --no-phasing: input VCF/BCF is already phased, do not phase input prior to
                local ancestry analysis

  --assume-reference: for any SNP in reference data for which no record is
                      in the input VCF/BCF, substitute the homozygous reference
                      allele for all samples in input. NOTE: If missing data
		      (./. or .|.) is explicitly given in the input, reference
		      alleles will not be substituted. Explict missing data is ok.

		      IMPORTANT: use this option only with high-coverage WGS data
		      
		      If this option is not specified, only SNPs found in the
		      intersection of the input and the reference data will be used.
    
   --fill-missing: This will substitute the phased reference homozygote genotype for
                   sites with missing data and automatically turn on --assume-reference.
                   Use this option if your input VCF has many samples that were merged 
                   together from single sample VCFs, and genome sequencing coverage is
                   high for all samples.

   For local ancestry analysis:
   Built-in reference panel groups the 1KG data into 5 reference populations: European,
   East Asian, African, South Asian, and Native American, selecting only samples which
   appear to be of almost pure ancestry in these groups. All other 1KG samples are
   excluded.

   For phasing:
   Entire 1KG panel of samples is used a reference haplotypes

   Phasing is performed by Eagle v2.3 author Po-Ru Loh, (C) 2015-2016 Harvard University
   distributed under the GNU GPL v3 open source license.

   local ancestry analysis is performed by RFMIX v2.X author Mark Koni Wright,
   (C) 2015-2016 Mark Wright, Stanford University. RFMIX and this software may be used
   royalty free for academic and government research use. Commericial use of RFMIX
   and this software package must be licensed for these uses from Stanford University.
   
EOF
  exit -1
}

my ($vcf_fname, $no_phasing, $assume_reference, $fill_missing, $run_script) = ("", 0, 0, 0, 0);
my $run_chms = join(",",1..22);
$ENV{ANCESTRY_ROOT} = "." unless defined $ENV{ANCESTRY_ROOT};
$ENV{ANCESTRY_ROOT} .= "/" unless $ENV{ANCESTRY_ROOT} =~ m/\/$/; 
my $ref_basename = "$ENV{ANCESTRY_ROOT}rfmix-reference/1KG.20ac.all";
my $debug = 0;
my %args;
$args{'--vcf'}              = [ \$vcf_fname,          1 ];
$args{'--ref'}              = [ \$ref_basename,       0 ];
$args{'--no-phasing'}       = [ \$no_phasing,         0 ];
$args{'--assume-reference'} = [ \$assume_reference,   0 ];
$args{'--fill-missing'}     = [ \$fill_missing,       0 ];
$args{'--debug'}            = [ \$debug,              0 ];
$args{'--run'}              = [ \$run_script,         0 ];
$args{'--chm'}              = [ \$run_chms,           1 ];
cmdline_args::get_options(\%args, \@ARGV);

unless ($run_script || defined("$ENV{RFMIX_REFERENCE}")) {
  exec(". config && $0 " . join(" ",@ARGV,"--run"));
}

chdir($ENV{ANCESTRY_ROOT}) if $ENV{ANCESTRY_ROOT};
#$ENV{PATH} = "$ENV{ANCESTRY_ROOT}/bin:$ENV{PATH}";
#$ENV{BCFTOOLS_PLUGINS} = "$ENV{ANCESTRY_ROOT}/bin/bcftools_plugins";

my $ref_fname = "$ref_basename";
if ( -f "$ref_basename.bcf.gz" ) {
  $ref_fname = "$ref_basename.bcf.gz";
} elsif ( -f "$ref_basename.bcf" ) {
  $ref_fname = "$ref_basename.bcf";
} elsif ( -f "$ref_basename.vcf.gz" ) {
  echo_exec("bcftools view --output-type b --output-file $ref_basename.bcf.gz --threads 32 -l 1 $ref_basename.vcf.gz");
  $ref_fname = "$ref_basename.bcf.gz";
} elsif ( -f "$ref_basename.vcf" ) {
  echo_exec("bcftools view --output-type b --output-file $ref_basename.bcf.gz --threads 32 -l 1 $ref_basename.vcf");
  $ref_fname = "$ref_basename.bcf.gz";
} else {
  print STDERR "\nERROR: Can't find a VCF or BCF file for reference data with prefix $ref_basename\n";
  exit(-1);
}

if ( ! -f "$ref_basename.map" ) {
  print STDERR "\nERROR: Can't find reference subpopulation mapping file $ref_basename.map\n";
  exit(-1);
}

if ($vcf_fname eq "") {
  system($0);
  print STDERR "\nERROR: Specify VCF or BCF input file with --vcf <filename> option\n\n";
  exit(-1);
}
my $output_basename = $vcf_fname;
$output_basename =~ s/\.[vb]cf(\.gz|\.bgz|\.bz2|\.xz|)$//;
my $tmp_dname = "$output_basename" . sprintf(".%08X",rand(0xFFFFFFFF));
echo_exec("mkdir -p $tmp_dname");
echo_exec("touch $output_basename.test");
echo_exec("id");
echo_exec("rm -f $output_basename.rfmix.msp.tsv");
echo_exec("rm -f $output_basename.rfmix.fb.tsv");
echo_exec("rm -f $output_basename.rfmix.Q");
if (! open(F, "<$vcf_fname") ) {
  print STDERR "Can't open input VCF/BCF file \"$vcf_fname\" ($!)";
  exit -1;
}
close F;

$assume_reference = 1 if $fill_missing;
if ($assume_reference) {
  my $fill_missing_cmd = "";
  if ($fill_missing) {
    $fill_missing_cmd = "set-reference-homozygote.py | bcftools view --output-type b --threads 32";
  } else {
    $fill_missing_cmd = "bcftools view --output-type b --threads 32";
  }
  
  if (echo_exec("/usr/bin/time --format='%e sec\\t%E\\t%M KB' insert-reference-homozygote.py $vcf_fname $ref_fname | $fill_missing_cmd > $tmp_dname/tmp.filled.bcf.gz")) {
    print STDERR "\nFailed to insert homozygous reference genotypes at ancestry reference sites.\n\n";
    exit -1;
  }
  
  $vcf_fname = "$tmp_dname/tmp.filled.bcf.gz";
}

if (! -f "$vcf_fname.csi" && ! -f "$vcf_fname.tbi" ) {
  echo_exec("bcftools index $vcf_fname");
}

if ( -f "hapmap-phase2-genetic-map.tsv.gz" && ! -f "hapmap-phase2-henetic-map.tsv" ) {
  echo_exec("gzip -dc hapmap-phase2-genetic-map.tsv.gz > hapmap-phase2-genetic-map.tsv");
}

for my $chm ( split/,/,$run_chms ) {
  
  my $current_vcf_fname = "$tmp_dname/tmp.$chm.bcf.gz";
  echo_exec("bcftools view --output-type b --threads 32 --regions $chm $vcf_fname > $current_vcf_fname");
  echo_exec("bcftools index $current_vcf_fname");
  unless ($no_phasing) {
    if (echo_exec("eagle --geneticMapFile $ENV{ANCESTRY_ROOT}/phasing-reference/genetic_map_hg19_withX.txt.gz --numThreads 24 --vcfRef $ref_fname --vcfTarget $current_vcf_fname --vcfOutFormat b --outPrefix $tmp_dname/tmp.phased.$chm --chrom $chm --noImpMissing")) {
      print STDERR "\nWARNING: Failed to phase chromosome $chm - skipping ancestry analysis for this chromosome.\n";
      next;
    }
    $current_vcf_fname = "$tmp_dname/tmp.phased.$chm.bcf";
    echo_exec("bcftools index $current_vcf_fname");      
  }
  
  if (echo_exec("rfmix -f $current_vcf_fname -r $ref_fname -m $ref_basename.map -g $ENV{ANCESTRY_ROOT}/rfmix-reference/hapmap-phase2-genetic-map.tsv -o $tmp_dname/tmp.rfmix.$chm --chromosome=$chm --crf-spacing=0.1 --rf-window-size=0.1 -G 8 -t 100 --max-missing=0.1 --rf-minimum-snps=20 --random-seed=0xDEADBEEF --crf-weight=3")) {
    print STDERR "\nWARNING: RFMIX analysis failed on chromosome $chm\n\n";
    next;
  }
  echo_exec("cat $tmp_dname/tmp.rfmix.$chm.msp.tsv >> $output_basename.rfmix.msp.tsv");
  echo_exec("cat $tmp_dname/tmp.rfmix.$chm.fb.tsv >> $output_basename.rfmix.fb.tsv");
  echo_exec("cat $tmp_dname/tmp.rfmix.$chm.rfmix.Q >> $output_basename.rfmix.Q");
}
echo_exec("rm -rf $tmp_dname");

sub echo_exec {
  my @args = @_;

  my $cmd = join(" ",@args);
  print "$cmd\n";
  my $rval = system($cmd);
  if ($rval & 127) {
    my $signal = $rval & 127;
    print STDERR "\n\nTerminating analysis due to signal $signal\n";
    exit $signal
  }
}
