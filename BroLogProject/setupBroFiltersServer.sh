#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cd /etc/logstash/conf.d/
sudo wget -N https://raw.githubusercontent.com/timmolter/logstash-dfir/master/conf_files/bro/bro-x509_log.conf




cd /opt/logstash
sudo bin/plugin install logstash-filter-translate
sudo service logstash configtest
sudo systemctl restart logstash
