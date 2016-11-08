#!/bin/bash

if [ $(whoami) = "root" ]; then # if run as root

# prepare system
apt-get update -y

# install glusterfs
apt-get install -y python-software-properties
add-apt-repository ppa:semiosis/ubuntu-glusterfs-3.4
apt-get update -y
apt-get install -y glusterfs-server

else # not run as root
    echo "this program must be run as root"
    echo "exiting"
fi
