#!/bin/bash

# settings
DATA_DIRECTORY=/exports

if [ $(whoami) = "root" ]; then # if run as root

# gather information
read -p "Data Directory ("$DATA_DIRECTORY"): " $DATA_DIRECTORY_NEW
if [ $DATA_DIRECTORY_NEW ]; then
    DATA_DIRECTORY=$DATA_DIRECTORY_NEW
fi

# prepare system
apt-get update -y

# install glusterfs
apt-get install -y python-software-properties
add-apt-repository ppa:semiosis/ubuntu-glusterfs-3.4
apt-get update -y
apt-get install -y glusterfs-server

# create data directory
mkdir -p $DATA_DIRECTORY
chmod -R 777 $DATA_DIRECTORY

# open permissions
echo "option rpc-auth-allow-insecure on" | tee -a /etc/glusterfs/glusterd.vol
service glustarfs-server stop
service glustarfs-server start

else # not run as root
    echo "this program must be run as root"
    echo "exiting"
fi
