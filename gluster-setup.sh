#!/bin/bash

# settings
NODE_2=rancher
NODE_1_DOMAIN=node1.example.com
NODE_2_DOMAIN=node2.example.com
VOLUME_NAME=rancher-storage
DATA_DIRECTORY=/exports

if [ $(whoami) = "root" ]; then # if run as root

# gather information
read -p "Node 2 ("$NODE_2"): " $NODE_2_NEW
if [ $NODE_2_NEW ]; then
    NODE_2=$NODE_2_NEW
fi
read -p "Volume Name ("$VOLUME_NAME"): " $VOLUME_NAME_NEW
if [ $VOLUME_NAME_NEW ]; then
    VOLUME_NAME=$VOLUME_NAME_NEW
fi
read -p "Node 1 Domain ("$NODE_1_DOMAIN"): " $NODE_1_DOMAIN_NEW
if [ $NODE_1_DOMAIN_NEW ]; then
    NODE_1_DOMAIN=$NODE_1_DOMAIN_NEW
fi
read -p "Node 2 Domain ("$NODE_2_DOMAIN"): " $NODE_2_DOMAIN_NEW
if [ $NODE_2_DOMAIN_NEW ]; then
    NODE_2_DOMAIN=$NODE_2_DOMAIN_NEW
fi
read -p "Data Directory ("$DATA_DIRECTORY"): " $DATA_DIRECTORY_NEW
if [ $DATA_DIRECTORY_NEW ]; then
    DATA_DIRECTORY=$DATA_DIRECTORY_NEW
fi

# peer with nodes
gluster peer probe $NODE_2
gluster peer status

# create storage volume
mkdir -p $DATA_DIRECTORY
gluster volume create $VOLUME_NAME replica 2 transport tcp $NODE_1_DOMAIN:$DATA_DIRECTORY $NODE_2_DOMAIN:$DATA_DIRECTORY force
gluster volume start $VOLUME_NAME

else # not run as root
    echo "this program must be run as root"
    echo "exiting"
fi
