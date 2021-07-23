#!/bin/bash
add-apt-repository ppa:ondrej/php
apt-get update -y
apt-get install apache2 mysql-client php7.4 libapache2-mod-php7.4 -y
apt-get install graphviz aspell ghostscript clamav php7.4-pspell php7.4-curl php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-ldap php7.4-zip php7.4-soap php7.4-mbstring -y
service apache2 restart
apt-get install git -y
MY_IP=$(wget -qO- checkip.amazonaws.com)
cd /opt
git clone git://git.moodle.org/moodle.git
cd moodle
git branch -a
git branch --track MOODLE_39_STABLE origin/MOODLE_39_STABLE
git checkout MOODLE_39_STABLE
cp -R /opt/moodle /var/www/html/
mkdir /var/www/moodledata
chown -R www-data /var/www/moodledata
chmod -R 777 /var/www/moodledata
chown -R www-data.www-data /var/www/html/moodle
chmod -R 777 /var/www/html/moodle
sudo -u www-data /usr/bin/php /var/www/html/moodle/admin/cli/install.php --wwwroot=http://$MY_IP/moodle --dataroot=/var/www/moodledata/ --dbtype=mysqli --dbhost=${db_moodle_url} --dbname=moodle --dbuser=moodle --dbpass=Perd0le! --fullname=moodle2 --shortname=moodle2 --adminpass=Pa\$\$w0rd --non-interactive --agree-license
chmod -R 0755 /var/www/html/moodle