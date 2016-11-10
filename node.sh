#!/bin/bash

# settings
DATA_DIRECTORY=/exports/
VOLUME_MOUNT=/dev/disk/by-id/google-disk-1

if [ $(whoami) = "root" ]; then # if run as root

# gather information
read -p "Data Directory ("$DATA_DIRECTORY"): " DATA_DIRECTORY_NEW
if [ $DATA_DIRECTORY_NEW ]; then
    DATA_DIRECTORY=$DATA_DIRECTORY_NEW
fi
read -p "Volume Mount ("$VOLUME_MOUNT"): " VOLUME_MOUNT_NEW
if [ $VOLUME_MOUNT_NEW ]; then
    VOLUME_MOUNT=$VOLUME_MOUNT_NEW
fi

# prepare system
apt-get update -y

# install glusterfs
apt-get install -y python-software-properties
add-apt-repository ppa:semiosis/ubuntu-glusterfs-3.4
apt-get update -y
apt-get install -y glusterfs-server

# mount and create data directory
mkfs.xfs -i size=512 $VOLUME_MOUNT
mkdir -p $DATA_DIRECTORY
echo '$VOLUME_MOUNT $DATA_DIRECTORY xfs defaults 1 2' >> /etc/fstab
mount -a && mount
chmod -R 777 $DATA_DIRECTORY

# open permissions
sed -i "s/option transport.socket.read-fail-log off/option transport.socket.read-fail-log off\n    option rpc-auth-allow-insecure on/g" /etc/glusterfs/glusterd.vol
service glustarfs-server stop
service glustarfs-server start

else # not run as root
    echo "this program must be run as root"
    echo "exiting"
fi
