#!/bin/bash

set -x
set -e

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install based on OS type
if [ -f /etc/debian_version ]; then

        # Install dependencies
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	sudo apt-get install apt-transport-https
	echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
	sudo apt-get update -y && sudo apt-get install filebeat -y
	sudo update-rc.d filebeat defaults 95 10

elif [ -f /etc/redhat-release ]; then

        # Install dependencies
	sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elastic.repo << EOF
[elastic-5.x]
name=Elastic repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF	
	sudo yum install filebeat -y
	sudo chkconfig --add filebeat
	systemctl enable filebeat
fi


################################## Setup Filebeat ##################################
echo "Enter the Logstash Server IP Address or Domain name to send logs, followed by [ENTER]: "
read logstashServer

cat > /etc/filebeat/filebeat.yml << EOF
filebeat.prospectors:
- input_type: log

  # Paths that should be crawled and fetched. Glob based paths.
  paths:
    - /var/log/*.log
  document_type: syslog
  "files": [
    {
      "paths": [
        "/var/log/secure"
       ],
      "fields": { "type": "syslog" }
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/http.log"
        ],
        "fields": {"type": "BRO_httplog"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/dhcp.log"
        ],
        "fields": {"type": "BRO_dhcp"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/conn.log"
        ],
        "fields": {"type": "BRO_connlog"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/weird.log"
        ],
        "fields": {"type": "BRO_weirdlog"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/syslog.log"
        ],
        "fields": {"type": "BRO_syslog"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/ssl.log"
        ],
        "fields": {"type": "BRO_ssl"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/ssh.log"
        ],
        "fields": {"type": "BRO_ssh"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/snmp.log"
        ],
        "fields": {"type": "BRO_snmp"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/notice.log"
        ],
        "fields": {"type": "BRO_notice"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/files.log"
        ],
        "fields": {"type": "BRO_files"}
    },
    {
      "paths":[
        "/usr/local/bro/logs/current/dns.log"
        ],
        "fields": {"type": "BRO_dns"}
    }
   ]
#----------------------------- Logstash output --------------------------------
output.logstash:
  hosts: ["$logstashServer:5044"]
EOF

# Start filebeat and add to start-up
if [ -f /etc/debian_version ]; then
	service filebeat start
	sudo update-rc.d filebeat defaults
elif [ -f /etc/redhat-release ]; then
	systemctl enable filebeat 
	systemctl start filebeat 
fi












