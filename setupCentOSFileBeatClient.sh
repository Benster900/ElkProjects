#!/bin/bash

set -x
set -e

##################################### Get server certificate #####################################
echo -n "Enter your domain of server and press [ENTER]: "
read domainName
openssl s_client -showcerts -connect $domainName:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > $domainName.pem
mv $domainName.pem /etc/pki/tls/certs/$domainName.pem

##################################### Install/Setup filebeat #####################################
sudo yum -y install filebeat

cp  /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bak
sed -i 's/output.elasticsearch:/#output.elasticsearch:/g' /etc/filebeat/filebeat.yml
sed -i 's/hosts: ["localhost:9200"]/#hosts: ["localhost:9200"]/g' /etc/filebeat/filebeat.yml
sed -i 's/#output.logstash:/output.logstash:/g' /etc/filebeat/filebeat.yml
sed -i 's/#hosts: ["localhost:5044"]/hosts: ["'"$domainName"':5044"]/g' /etc/filebeat/filebeat.yml

sudo systemctl start filebeat
sudo systemctl enable filebeat
