#!/bin/bash

trap "echo trapped signal caught" HUP INT QUIT TERM

#USER_ID=${LOCAL_USER_ID:-9001}

#echo "Starting with UID: $USER_ID"
#useradd --shell /bin/bash -u $USER_ID -o -c "" -m user
#chmod 777 /root
#chown -R user /root
#chmod 755 /root/run-analysis.pl

id
cd /home/ancestry
. ./config
echo ./run-analysis.pl $@
./run-analysis.pl $@
