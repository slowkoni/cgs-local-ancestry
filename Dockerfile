# Start from a recent release of the 14.04 ubuntu distribution
FROM ubuntu:14.04.5

MAINTAINER Mark Koni Wright <mhwright@stanford.edu>
LABEL version="1.04"

# Update base distribution and install needed packages
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install -y gcc python python-all python-all-dev perl perl-modules awscli s3cmd openssh-server openssh-client gnupg time

# Listen for ssh - useful for debugging or finding out what is going on
# Need to set password for a user or add a key file though
EXPOSE 22

ARG UID=1000
RUN useradd --non-unique -u $UID --home /home/ancestry --user-group --create-home --shell /bin/bash ancestry
ADD . /home/ancestry
ADD .s3cfg /home/ancestry

# If we don't create the mount point from the docker file, the mount
# isn't writable from within the container
RUN mkdir -p /home/ancestry/shared

RUN chown -R ancestry:ancestry /home/ancestry

# Get the reference data which we will manage externally
USER ancestry
RUN s3cmd --no-check-md5 get s3://rfmix-reference-data/1KG.hs37d5.reference.tar - | tar -C /home/ancestry -xvf -

#
ENTRYPOINT ["/home/ancestry/start.sh"]


