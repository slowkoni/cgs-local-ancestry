# Start from a recent release of the 14.04 ubuntu distribution
FROM ubuntu:14.04.5

# Update base distribution and install needed packages
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install gcc python python-all python-all-dev perl perl-modules awscli s3cmd

# Get the reference data which we will manage externally
#RUN s3cmd get s3://rfmix-reference-data/1KG.20ac.all.bcf.gz phasing-reference/
#RUN s3cmd get s3://rfmix-reference-data/1KG.20ac.all.bcf.gz.csi phasing-reference/



