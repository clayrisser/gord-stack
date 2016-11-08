#!/bin/bash

# settings
RANCHER_MYSQL_DATABASE=rancher
MYSQL_PASSWORD=hellodocker
RANCHER_PORT=80
OVIRT_POSTGRES_DATABASE=postgres
POSTGRES_PASSWORD=hellodocker
OVIRT_PORT=8080
OVIRT_PASSWORD=hellodocker

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
read -p "Ovirt Postgres Database ("$OVIRT_POSTGRES_DATABASE"): " $OVIRT_POSTGRES_DATABASE_NEW
if [ $OVIRT_POSTGRES_DATABASE_NEW ]; then
    OVIRT_POSTGRES_DATABASE=$OVIRT_POSTGRES_DATABASE_NEW
fi
read -p "Postgres Password ("$POSTGRES_PASSWORD"): " $POSTGRES_PASSWORD_NEW
if [ $POSTGRES_PASSWORD_NEW ]; then
    POSTGRES_PASSWORD=$POSTGRES_PASSWORD_NEW
fi
read -p "Rancher Port ("$RANCHER_PORT"): " $RANCHER_PORT_NEW
if [ $RANCHER_PORT_NEW ]; then
    RANCHER_PORT=$RANCHER_PORT_NEW
fi
read -p "Ovirt Port ("$OVIRT_PORT"): " $OVIRT_PORT_NEW
if [ $OVIRT_PORT_NEW ]; then
    OVIRT_PORT=$OVIRT_PORT_NEW
fi
read -p "Ovirt Password ("$OVIRT_PASSWORD"): " $OVIRT_PASSWORD_NEW
if [ $OVIRT_PASSWORD_NEW ]; then
    OVIRT_PASSWORD=$OVIRT_PASSWORD_NEW
fi

# prepare system
yum update -y

# install docker
tee /etc/yum.repos.d/docker.repo <<EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
yum install -y docker-engine
systemctl enable docker.service
systemctl start docker
docker run --rm hello-world

# install mariadb
docker run -d --name rancherdb --restart=unless-stopped -v /var/lib/mysql/:/var/lib/mysql/ \
       -e MYSQL_DATABASE=$RANCHER_MYSQL_DATABASE \
       -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD \
       mariadb:latest

# install postgres
docker run -d --name ovirtdb --restart=unless-stopped -v /var/lib/postgresql/data/:/var/lib/postgresql/data/ \
       -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
       postgres:latest
echo "Waiting for container to start"
sleep 30
echo "Modifying configuration"
sed -i "s/max_connections = 100/max_connections = 150/g" /var/lib/postgresql/data/postgresql.conf
echo "Restarting container"
docker restart ovirtdb

# install rancher
docker run -d --restart=unless-stopped --link rancherdb:mysql -p $RANCHER_PORT:8080 \
       -e CATTLE_DB_CATTLE_MYSQL_HOST=$MYSQL_PORT_3306_TCP_ADDR \
       -e CATTLE_DB_CATTLE_MYSQL_PORT=3306 \
       -e CATTLE_DB_CATTLE_MYSQL_NAME=$RANCHER_MYSQL_DATABASE \
       -e CATTLE_DB_CATTLE_USERNAME=root \
       -e CATTLE_DB_CATTLE_PASSWORD=$MYSQL_PASSWORD \
       rancher/server:latest

# install ovirt
docker run -d --restart=unless-stopped --link ovirtdb:postgres -p $OVIRT_PORT:8443 \
       -e POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR \
       -e POSTGRES_PORT=5432 \
       -e POSTGRES_DB=$OVIRT_POSTGRES_DATABASE \
       -e POSTGRES_USER=postgres \
       -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
       -e OVIRT_PASSWORD=$OVIRT_PASSWORD \
       rmohr/ovirt-engine:latest

else # not run as root
echo "this program must be run as root"
echo "exiting"
fi
