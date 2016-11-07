#!/bin/bash

# settings
RANCHER_MYSQL_DATABASE=rancher
MYSQL_PASSWORD=hellodocker
OVIRT_POSTGRES_DATABASE=ovirt
POSTGRES_PASSWORD=hellodocker
RANCHER_PORT=80

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
mkdir -p /var/lib/postgresql/data/
cp ./postgresql.conf /var/lib/postgresql/data/
docker run -d --name ovritdb --restart=unless-stopped -v /var/lib/postgresql/data/:/var/lib/postgresql/data/ \
       -e POSTGRES_DB=$OVIRT_POSTGRES_DATABASE \
       -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
       postgres:latest

# install rancher
docker run -d --restart=unless-stopped --link rancherdb:mysql -p $RANCHER_PORT:8080 \
       -e CATTLE_DB_CATTLE_MYSQL_HOST=$MYSQL_PORT_3306_TCP_ADDR \
       -e CATTLE_DB_CATTLE_MYSQL_PORT=3306 \
       -e CATTLE_DB_CATTLE_MYSQL_NAME=$RANCHER_MYSQL_DATABASE \
       -e CATTLE_DB_CATTLE_USERNAME=root \
       -e CATTLE_DB_CATTLE_PASSWORD=$MYSQL_PASSWORD \
       rancher/server:latest

else # not run as root
echo "this program must be run as root"
echo "exiting"
fi
