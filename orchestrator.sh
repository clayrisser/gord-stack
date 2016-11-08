#!/bin/bash

# settings
RANCHER_MYSQL_DATABASE=rancher
MYSQL_PASSWORD=hellodocker
RANCHER_PORT=80
DUPLICATI_PASSWORD=hellodocker

if [ $(whoami) = "root" ]; then # if run as root

# gather information
read -p "Rancher MYSQL Database ("$RANCHER_MYSQL_DATABASE"): " $RANCHER_MYSQL_DATABASE_NEW
if [ $RANCHER_MYSQL_DATABASE_NEW ]; then
    RANCHER_MYSQL_DATABASE=$RANCHER_MYSQL_DATABASE_NEW
fi
read -p "MYSQL Password ("$MYSQL_PASSWORD"): " $MYSQL_PASSWORD_NEW
if [ $MYSQL_PASSWORD_NEW ]; then
    MYSQL_PASSWORD=$MYSQL_PASSWORD_NEW
fi
read -p "Rancher Port ("$RANCHER_PORT"): " $RANCHER_PORT_NEW
if [ $RANCHER_PORT_NEW ]; then
    RANCHER_PORT=$RANCHER_PORT_NEW
fi
read -p "Duplicati Password ("$DUPLICATI_PASSWORD"): " $DUPLICATI_PASSWORD_NEW
if [ $DUPLICATI_PASSWORD_NEW ]; then
    DUPLICATI_PASSWORD=$DUPLICATI_PASSWORD_NEW
fi

# prepare system
apt-get update -y

# install docker
apt-get install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-cache policy docker-engine
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get update -y
apt-get install -y docker-engine
service docker start
docker run hello-world

# install mariadb
docker run -d --name rancherdb --restart=unless-stopped \
       -v /var/lib/mysql/:/var/lib/mysql/ \
       -e MYSQL_DATABASE=$RANCHER_MYSQL_DATABASE \
       -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD \
       mariadb:latest

# install rancher
docker run -d --restart=unless-stopped --link rancherdb:mysql -p $RANCHER_PORT:8080 \
       -e CATTLE_DB_CATTLE_MYSQL_HOST=$MYSQL_PORT_3306_TCP_ADDR \
       -e CATTLE_DB_CATTLE_MYSQL_PORT=3306 \
       -e CATTLE_DB_CATTLE_MYSQL_NAME=$RANCHER_MYSQL_DATABASE \
       -e CATTLE_DB_CATTLE_USERNAME=root \
       -e CATTLE_DB_CATTLE_PASSWORD=$MYSQL_PASSWORD \
       rancher/server:latest

# install duplicati
docker run -d --restart=unless-stopped \
       -v /root/.config/Duplicati/:/root/.config/Duplicati/ \
       -v /var/lib/mysql/:/var/lib/mysql/ \
       -e DUPLICATI_PASS=$DUPLICATI_PASSWORD \
       -e MONO_EXTERNAL_ENCODINGS=UTF-8 \
       -p 8200:8200 \
       intersoftlab/duplicati:canary

else # not run as root
echo "this program must be run as root"
echo "exiting"
fi
