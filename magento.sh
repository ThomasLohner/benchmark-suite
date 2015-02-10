#!/usr/bin/env bash

if [ $# -eq 0 ]
then
  echo "Proivde apache user name as param"
  exit
fi

DOMAIN="www.invaliddomain.de"
BASEDIR="/var/www/${DOMAIN}/magento/"
URL="http://${DOMAIN}/magento/"
DBHOST=$(facter ipaddress)
DBPASS=$(pwgen 12 1)
DBUSER="mage"
DBNAME="magento"
ADMINPASS=$(pwgen -n 12 1)
ENCRYPTIONKEY=$(pwgen 24 1)
OSUSER=$1

# download magento core and sample data
wget https://files.syseleven.de/~tlohner/magento-1.9.1.0.tar.gz -O /tmp/magento-1.9.1.0.tar.gz
wget https://files.syseleven.de/~tlohner/magento-sample-data-1.9.1.0.tar.gz -O /tmp/magento-sample-data-1.9.1.0.tar.gz
wget https://files.syseleven.de/~tlohner/magento_sample_data_for_1.9.1.0.sql.tar.gz -O /tmp/magento_sample_data_for_1.9.1.0.sql.tar.gz

# prepare docroot
mkdir -p $BASEDIR
tar xfvz /tmp/magento-1.9.1.0.tar.gz --directory $BASEDIR --strip-components=1
tar xvfz /tmp/magento-sample-data-1.9.1.0.tar.gz --directory $BASEDIR --strip-components=1
tar xfvz /tmp/magento_sample_data_for_1.9.1.0.sql.tar.gz --directory /tmp/
chown -R $OSUSER $BASEDIR

# fix htaccess for apache 2.4
sed -i '/order allow,deny/Id' /var/www/www.invaliddomain.de/magento/.htaccess
sed -i '/Allow from all/Id' /var/www/www.invaliddomain.de/magento/.htaccess
sed -i '/Deny from all/Id' /var/www/www.invaliddomain.de/magento/.htaccess

# create database
mysql --defaults-file=/root/.my.cnf -e "create database $DBNAME; grant all on $DBNAME.* to '$DBUSER'@'$DBHOST' identified by '$DBPASS'; flush privileges;"

# load sample data
mysql --defaults-file=/root/.my.cnf $DBNAME < /tmp/magento_sample_data_for_1.9.1.0.sql

# setup magento
php -f ${BASEDIR}install.php --\
  --license_agreement_accepted yes \
  --locale de_DE \
  --timezone 'Europe/Berlin' \
  --default_currency EUR \
  --db_host $DBHOST \
  --db_name $DBNAME \
  --db_user $DBUSER \
  --db_pass $DBPASS \
  --url $URL \
  --use_rewrites yes \
  --use_secure no \
  --use_secure_admin no \
  --secure_base_url $URL \
  --admin_lastname Eleven \
  --admin_firstname Sys \
  --admin_email admin@invaliddomain.de \
  --admin_username admin \
  --admin_password $ADMINPASS \
  --encryption_key $ENCRYPTIONKEY

# mooooo
PATH=$PATH:/usr/games/

MESSAGE="
I've installed magento at:

$URL

MySQL Credentials:
User: $DBUSER
Pass: $DBPASS 
Host: $DBHOST
DB:   $DBNAME

Remember to add this line to your local /etc/hosts-file:
$(curl -s ip.syseleven.de) $DOMAIN

Start benchmarking with:

ab -c 1 -t 60 ${URL}catalogsearch/result/?q=dress

siege -v -b -c 1 -t 60S -l /dev/null ${URL}catalogsearch/result/?q=dress

"
echo "$MESSAGE" | cowsay -n

# save message to  /etc/motd
echo "$MESSAGE" | cowsay -n >/etc/motd

