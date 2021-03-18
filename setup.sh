#!/bin/bash

if [ "$1" != "" ]; then
    mattermost_version="$1"
	echo 'Mattermost Version is ' $mattermost_version
else
	echo "Mattermost version is required"
    exit 1
fi

if [ "$2" != "" ]; then
    DATABASE_USER_PASS="$2"
	echo 'database user password exists'
else
	echo "postgres user password required"
    exit 1
fi

if [ "$3" != "" ]; then
    DATABASE_ROOT_PASS="$3"
	echo 'database root password exists'
else
	echo "postgres root password required"
    exit 1
fi

echo "Updating and Upgrading"
apt-get update -y && apt-get upgrade -y

DB_SERVER_NAME="postgresServer"
DATABASE_USER='mmuser'
DATABASE_NAME='mattermost'

echo "Installing Docker, and ldapscripts"
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
apt-get install -y -q ldapscripts jq

echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -qq -y update
sudo apt-get install docker-ce docker-ce-cli containerd.io postgresql-client -y


printf "\n
########################################### \n
########################################### \n
\n
Setting up Postgres \n
\n 
########################################### \n
########################################### \n
\n
# "

docker pull postgres:latest

docker run --restart always \
--name=$DB_SERVER_NAME \
-p 5432:5432 \
-e POSTGRES_PASSWORD=$DATABASE_ROOT_PASS \
-e POSTGRES_USER=$DATABASE_USER \
-e POSTGRES_PASSWORD=$DATABASE_USER_PASS \
-e POSTGRES_DB=$DATABASE_NAME \
-v /opt/postgres/data:/var/lib/postgresql/data \
-h '*' \
-d postgres


printf "\n
########################################### \n
########################################### \n
\n
Setting up LDAP \n
\n 
########################################### \n
########################################### \n
\n
# "

echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

docker pull rroemhild/test-openldap
docker run --restart always --name=ldap -p 10389:10389 -p 10636:10636 -d rroemhild/test-openldap

printf "\n
########################################### \n
########################################### \n
\n
Setting up Mattermost \n
\n 
########################################### \n
########################################### \n
\n
# "

rm -rf /opt/mattermost

echo /vagrant/mattermost-$mattermost_version-linux-amd64.tar.gz

if [[ ! -f /vagrant/mattermost-$mattermost_version-linux-amd64.tar.gz ]]; then
	echo "Downloading Mattermost"
	echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
	wget -P /vagrant/ https://releases.mattermost.com/$mattermost_version/mattermost-$mattermost_version-linux-amd64.tar.gz
fi

cp /vagrant/mattermost-$mattermost_version-linux-amd64.tar.gz ./

tar -xzf mattermost*.gz

rm mattermost*.gz
mv mattermost /opt

mkdir /opt/mattermost/data
mv /opt/mattermost/config/config.json /opt/mattermost/config/config.orig.json
jq -s '.[0] * .[1]' /opt/mattermost/config/config.orig.json /vagrant/config.json > /opt/mattermost/config/config.json

cp /vagrant/e20license.txt /opt/mattermost/license.txt

useradd --system --user-group mattermost
chown -R mattermost:mattermost /opt/mattermost
chmod -R g+w /opt/mattermost

cp /vagrant/mattermost.service /lib/systemd/system/mattermost.service
systemctl daemon-reload

cd /opt/mattermost
chown -R mattermost:mattermost /opt/mattermost/

bin/mattermost user create --email admin@planetexpress.com --username admin --password admin --system_admin
bin/mattermost team create --name planet-express --display_name "Planet Express" --email "admin@planetexpress.com"
bin/mattermost team create --name olympus --display_name "Administrative Staff" --email "admin@planetexpress.com"
bin/mattermost team create --name ship-crew --display_name "Ship's Crew" --email "admin@planetexpress.com"
bin/mattermost team add planet-express admin@planetexpress.com
bin/mattermost team add olympus admin@planetexpress.com


systemctl start mattermost


psql "host=127.0.0.1 port=5432 dbname=$DATABASE_NAME user=$DATABASE_USER password=$DATABASE_USER_PASS" < /vagrant/db_setup.pgsql

# IP_ADDR=`/sbin/ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`

printf '=%.0s' {1..80}
echo 
echo '                     VAGRANT UP!'
echo "GO TO http://127.0.0.1:8065 and log in with \`professor\`"
echo
printf '=%.0s' {1..80}
