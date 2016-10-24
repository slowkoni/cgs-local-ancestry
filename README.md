## cgs-local-ancestry
Local ancestry analysis pipeline for Stanford Clinical Genome Service and Undiagnosed Disease Network

### Prerequisites
Docker version 1.12 or higher

### To build the docker image

`docker build --build-arg UID=$UID -t cgs-local-ancestry cgs-local-ancestry`

This command may take a few minutes because the build process will download the phasing and
local ancestry reference data from Amazon S3. This is several GB of data and too large to
store in a git repo.

### To run an unphased VCF or BCF file through the pipeline and receive RFMIX results

Create a directory called shared (or whatever you want and adjust below)
Copy your BCF or VCF there. For example below, we'll call it my-genome.bcf.gz

````
mkdir -p shared
cp path/to/my-genome.bcf.gz shared/my-genome.bcf.gz
docker run -t -i -v $PWD/shared:/home/ancestry/shared cgs-local-ancestry --vcf shared/my-genome.bcf.gz
````

You do not need to create a separate directory for every run. You can use the same directory, and run the docker container on different VCF/BCF files separately. Outputs will be created within the shared/ directory using the same prefix as the input VCF/BCF file. The container will automatically detect whether the file is VCF or BCF and whether or not it is gzip'd. An index is not necessary, the container will create them when they are needed.

If your VCF was called as a single sample and thus homozygous reference genotypes at most known variable sites in the standing population are not present in the file, but sequencing coverage is high, add the argument --assume-reference to insert homozygous reference genotype calls where needed. If you have merged multiple single sample VCF files into a single multiple sample VCF file, and the merging tool or your script has substituded missing genotype calls (./. or just .) at sites that were not given in one or more of the merged single sample VCFs, the option --fill-missing will substitute reference homozygous genotype calls at all fully missing data sites. Partially missing (eg., ./1 or 1|. or something) do not have reference alleles substituted for the missing allele. This is ok, the pipeline can handle missing data where it is missing-at-random appropriately, but it can not handle very large amounts of missing data with a strong bias toward missing reference alleles.

If your VCF is already phased, add the argument --no-phasing to prevent this package from performing phasing. If your data is trio-phased, use this option as this package will perform population phasing using the 1000 genomes reference haplotypes otherwise. Phasing is required for local ancestry analysis, so without this option phasing is performed by default even if the VCF indicates the data is phased.

If you want to test the package on just one chromosome, adding the option --debug will trigger the package to process only chromosome 22. Otherwise, all chromosomes will be analyzed.

### Output

At present, RFMIX output for all chromosomes will be given in the same directory that the input VCF/BCF was, indicated by my-genome.rfmix.msp.tsv (maximum state path ancestry assignment), my-genome.rfmix.fb.tsv (marginal probability of each ancestry), and my-genome.rfmix.Q (overall ancestry proportion for each chromosome). The .msp.tsv and .fb.tsv files give spans of the chromosome for which the ancestry assignment, or marginal probability vector, apply and are reduced to the minimum number of lines needed to represent all local ancestry switches across all samples. See RFMIX website for more documentation on these files.

### Limitations

There is no built in option to trio-phase data when a VCF containing proband and parents is specified. To take advantage of having a trio for phasing, trio-phasing must be performed externally prior to supplying the phased VCF to this package.

This package expects whole genome sequencing data, or high density genotyping array data (do not use --assume-reference or --fill-missing in this case) and has not been evaluated on exome or gene panel data. There is no option at present to specify which regions of the genome are expected to have sequencing coverage.

Eventually, this package will output an annotated VCF file with ancestry calls. At present, only files will give non-redundant regions of single ancestry calls is produced, likely requiring downstream analysis stages.

RFMIX is presently slow on single sample or small number of samples VCF files, because it is designed for query inputs with large number of samples.

The X chromosome is currently ignored.

Due to licensing restrictions, this package may not be used for commercial use free of charge. Please contact Stanford Office of Technology Licensing for a commercial-use license for RFMIX for these uses. See LICENSE file for more information on RFMIX licensing and that of other programs used in this package.

### License

(c) 2016 Mark Koni Hamilton Wright, Stanford University School of Medicine

This package contains software used under several different licenses. Please see LICENSE file. 
