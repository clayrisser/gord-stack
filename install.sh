#!/bin/bash

# settings
ROOT_MYSQL_PASSWORD=hellodocker
RANCHER_PORT=80
RANCHER_MYSQL_HOST=localhost
RANCHER_MYSQL_PORT=3306
RANCHER_MYSQL_DATABASE=rancher
RANCHER_MYSQL_USERNAME=rancher
RANCHER_MYSQL_PASSWORD=hellodocker

if [ $(whoami) = "root" ]; then # if run as root

# gather information
read -p "Root MYSQL Password ("$ROOT_MYSQL_PASSWORD"): " $ROOT_MYSQL_PASSWORD_NEW
if [ $ROOT_MYSQL_PASSWORD_NEW ]; then
    ROOT_MYSQL_PASSWORD=$ROOT_MYSQL_PASSWORD_NEW
fi
read -p "Rancher Port ("$RANCHER_PORT"): " $RANCHER_PORT_NEW
if [ $RANCHER_PORT_NEW ]; then
    RANCHER_PORT=$RANCHER_PORT_NEW
fi
read -p "Rancher MYSQL Host ("$RANCHER_MYSQL_HOST"): " $RANCHER_MYSQL_HOST_NEW
if [ $RANCHER_MYSQL_HOST_NEW ]; then
    RANCHER_MYSQL_HOST=$RANCHER_MYSQL_HOST_NEW
fi
read -p "Rancher MYSQL Port ("$RANCHER_MYSQL_PORT"): " $RANCHER_MYSQL_PORT_NEW
if [ $RANCHER_MYSQL_PORT_NEW ]; then
    RANCHER_MYSQL_PORT=$RANCHER_MYSQL_PORT_NEW
fi
read -p "Rancher MYSQL Database ("$RANCHER_MYSQL_DATABASE"): " $RANCHER_MYSQL_DATABASE_NEW
if [ $RANCHER_MYSQL_DATABASE_NEW ]; then
    RANCHER_MYSQL_DATABASE=$RANCHER_MYSQL_DATABASE_NEW
fi
read -p "Rancher MYSQL Username ("$RANCHER_MYSQL_USERNAME"): " $RANCHER_MYSQL_USERNAME_NEW
if [ $RANCHER_MYSQL_USERNAME_NEW ]; then
    RANCHER_MYSQL_USERNAME=$RANCHER_MYSQL_USERNAME_NEW
fi
read -p "Rancher MYSQL Password ("$RANCHER_MYSQL_PASSWORD"): " $RANCHER_MYSQL_PASSWORD_NEW
if [ $RANCHER_MYSQL_PASSWORD_NEW ]; then
    RANCHER_MYSQL_PASSWORD=$RANCHER_MYSQL_PASSWORD_NEW
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
yum install -y mariadb-server mariadb
systemctl start mariadb
mysqladmin -u root password $ROOT_MYSQL_PASSWORD
mysql -u root -p$ROOT_MYSQL_PASSWORD -e "UPDATE mysql.user SET Password=PASSWORD('$ROOT_MYSQL_PASSWORD') WHERE User='root'"
mysql -u root -p$ROOT_MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p$ROOT_MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p$ROOT_MYSQL_PASSWORD -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p$ROOT_MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$ROOT_MYSQL_PASSWORD' WITH GRANT OPTION;"
mysql -u root -p$ROOT_MYSQL_PASSWORD -e "FLUSH PRIVILEGES"
systemctl enable mariadb.service

# create rancher database
mysql -uroot -p$ROOT_MYSQL_PASSWORD -e "CREATE DATABASE $RANCHER_MYSQL_DATABASE /*\!40100 DEFAULT CHARACTER SET utf8 */;"
mysql -uroot -p$ROOT_MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $RANCHER_MYSQL_DATABASE.* TO '$RANCHER_MYSQL_USERNAME'@'%' IDENTIFIED BY '$RANCHER_MYSQL_PASSWORD';"
mysql -uroot -p$ROOT_MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

# install postgressdb
yum install -y postgresql-server postgresql-contrib
postgresql-setup initdb
sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
systemctl start postgresql
systemctl enable postgresql

# install rancher
docker run -d --restart=unless-stopped -p $RANCHER_PORT:8080 \
       -e CATTLE_DB_CATTLE_MYSQL_HOST=$RANCHER_MYSQL_HOST \
       -e CATTLE_DB_CATTLE_MYSQL_PORT=$RANCHER_MYSQL_PORT \
       -e CATTLE_DB_CATTLE_MYSQL_NAME=$RANCHER_MYSQL_DATABASE \
       -e CATTLE_DB_CATTLE_USERNAME=$RANCHER_MYSQL_USERNAME \
       -e CATTLE_DB_CATTLE_PASSWORD=$RANCHER_MYSQL_PASSWORD \
       rancher/server

else # not run as root
echo "this program must be run as root"
echo "exiting"
fi
