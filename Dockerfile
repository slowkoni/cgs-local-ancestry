# Start from a recent release of the 14.04 ubuntu distribution
FROM ubuntu:14.04.5

MAINTAINER Mark Koni Wright <mhwright@stanford.edu>
LABEL version="1.00"

# Update base distribution and install needed packages
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y gcc python python-all python-all-dev perl perl-modules awscli s3cmd openssh-server openssh-client gnupg

# Listen for ssh - useful for debugging or finding out what is going on
EXPOSE 22

ADD . /root
ADD .s3cfg /root

# Get the reference data which we will manage externally
RUN s3cmd get s3://rfmix-reference-data/1KG.hs37d5.reference.tar - | tar -C /root -xvf -

#
ENTRYPOINT ["/bin/bash", "-c", "cd /root && ./run-analysis.pl"]


