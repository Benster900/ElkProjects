#!/bin/bash

set -x
set -e


# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ ! -f /etc/redhat-release ]; then
	echo "This script is for CentOS"
	exit
fi


yum update -y && yum upgrade -y
##################################### Install Java ##################################
cd ~
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u73-b02/jdk-8u73-linux-x64.rpm"
sudo yum -y localinstall jdk-8u73-linux-x64.rpm
rm ~/jdk-8u*-linux-x64.rpm

##################################### Install/Setup Elasticsearch #####################################
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

echo '[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
' | sudo tee /etc/yum.repos.d/elasticsearch.repo
sudo yum -y install elasticsearch

sed -i 's/#network.host: 192.168.0.1/network.host: localhost/g' /etc/elasticsearch/elasticsearch.yml

systemctl enable elasticsearch
systemctl start elasticsearch

##################################### Install/Setup Kibana #####################################
echo '[kibana-5.x]
name=Kibana repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
' | sudo tee /etc/yum.repos.d/kibana.repo
sudo yum -y install kibana

sudo systemctl start kibana
sudo chkconfig kibana on

##################################### Install/Setup Nginx #####################################
yum -y install epel-release
yum -y install nginx httpd-tools
sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

#delete server block
sed -i -e '38,87d' /etc/nginx/nginx.conf

read -p "Create OpenSSL cert or Let's Encrypt Cert [L/O]" -n 1 -r
if [[ $REPLY =~ ^[Oo]$ ]]; then
	mkdir /etc/nginx/ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt

echo 'server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        server_name _;

        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html index.htm;

        ssl_certificate /etc/nginx/ssl/nginx.crt;
        ssl_certificate_key /etc/nginx/ssl/nginx.key;

	location / {
        	proxy_pass http://localhost:5601;
        	proxy_http_version 1.1;
        	proxy_set_header Upgrade $http_upgrade;
        	proxy_set_header Connection 'upgrade';
        	proxy_set_header Host $host;
        	proxy_cache_bypass $http_upgrade;
    	}
}
' | sudo tee /etc/nginx/conf.d/kibana.conf

sudo systemctl start nginx
sudo systemctl enable  nginx
sudo setsebool -P httpd_can_network_connect 1

else
	sudo yum install certbot
echo 'server {
        location ~ /.well-known {
          allow all;
        }
}
' | sudo tee /etc/nginx/conf.d/le-well-known.conf

	sudo systemctl start nginx
	sudo systemctl enable  nginx

	read -p "Enter domain name: " -e domainName
	sudo certbot certonly -a webroot --webroot-path=/usr/share/nginx/html -d $domainName -d www.$domainName
	sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

echo -e "server {
	listen 443 ssl;

        server_name ${domainName} www.${domainName};

        ssl_certificate /etc/letsencrypt/live/${domainName}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${domainName}/privkey.pem;

        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /etc/ssl/certs/dhparam.pem;
        ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:50m;
        ssl_stapling on;
        ssl_stapling_verify on;
        add_header Strict-Transport-Security max-age=15768000;

        # The rest of your server block
        root /usr/share/nginx/html;
        index index.html index.htm;

        location / {
                proxy_pass http://localhost:5601;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host $host;
                proxy_cache_bypass $http_upgrade;
        }
}
" | sudo tee /etc/nginx/conf.d/kibana.conf

	rm -rf /etc/nginx/conf.d/le-well-known.conf
	sudo systemctl restart nginx
  sudo setsebool -P httpd_can_network_connect 1


	sudo certbot renew
echo '30 2 * * 1 /usr/bin/certbot renew >> /var/log/le-renew.log
35 2 * * 1 /usr/bin/systemctl reload nginx
' >> /etc/crontab

systemctl start crond

fi

##################################### Install/Setup Logstash #####################################
echo '[logstash-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
' | sudo tee /etc/yum.repos.d/logstash.repo

sudo yum -y install logstash

read -p "Logstash encryption or no encryption [E/N]" -n 1 -r
if [[ $REPLY =~ ^[E]$ ]]; then

echo 'input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/nginx/ssl/nginx.crt"
    ssl_key => "/etc/nginx/ssl/nginx.key"
  }
}
' | sudo tee /etc/logstash/conf.d/02-beats-input.conf

else

echo 'input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/letsencrypt/live/$domain/fullchain.pem"
    ssl_key => "/etc/letsencrypt/live/$domain/privkey.pem"
  }
}
' | sudo tee /etc/logstash/conf.d/02-beats-input.conf

fi


#### Syslog filter ####
echo 'filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
' | sudo tee /etc/logstash/conf.d/10-syslog-filter.conf



#### Elasticsearch output ####
echo 'output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
' | sudo tee /etc/logstash/conf.d/30-elasticsearch-output.conf


sudo service logstash configtest
sudo systemctl restart logstash
sudo chkconfig logstash on
