## cgs-local-ancestry
Local ancestry analysis pipeline for Stanford Clinical Genome Service and Undiagnosed Disease Network

### Prerequisites
Docker version 1.12 or higher

### To build the docker image

`docker build --build-arg UID=$UID -t cgs-local-ancestry cgs-local-ancestry`

### To run an unphased VCF or BCF file through the pipeline and receive RFMIX results

Create a directory called shared (or whatever you want and adjust below)
Copy your BCF or VCF there. For example below, we'll call it my-genome.bcf.gz

`docker run -t -i -v \`pwd\`/shared:/home/ancestry/shared cgs-local-ancestry --vcf shared/my-genome.bcf.gz`

If your VCF was called as a single sample and thus homozygous reference genotypes are at most known variable sites in the genome are not present in the file, but sequencing coverage is high, add the argument --assume-reference to insert homozygous reference genotype calls where needed.

If your VCF is already phased, add the argument --no-phasing to prevent this package from performing phasing.

### Output

At present, RFMIX output for all chromosomes will be given in the same directory that the input VCF/BCF was, indicated by my-genome.rfmix.msp.tsv (maximum state path ancestry assignment), my-genome.rfmix.fb.tsv (marginal probability of each ancestry), and my-genome.rfmix.Q (overall ancestry proportion for each chromosome). The .msp.tsv and .fb.tsv files give spans of the chromosome for which the ancestry assignment, or marginal probability vector, apply and are reduced to the minimum number of lines needed to represent all local ancestry switches across all samples. See RFMIX website for more documentation on these files.

### Limitations

There is no option to fill missing data with homozygous reference genotypes at present. Thus, if you are merging single sample VCF files into one and then running this analysis, you must set these to homozygous reference yourself at present, if that is a reasonable assumption. Note that having a genotype present if and only if at least one non-reference allele was observed, is a huge bias to have in the input data.

### License

(c) 2016 Mark Koni Hamilton Wright, Stanford University School of Medicine

This package contains software used under several different licenses. Please see LICENSE file. 
