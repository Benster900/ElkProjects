#!/bin/bash

set -x
set -e

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Install git
if [ -f /etc/debian_version ]; then
	apt-get install git -y
elif [ -f /etc/redhat-release ]; then
	yum install git -y
fi

# Download 
cd /etc/logstash/conf.d/10-syslog-filter.conf

# Restart logstash service
if [ -f /etc/debian_version ]; then
	service logstas restart
elif [ -f /etc/redhat-release ]; then
	systemctl restart logstah
fi
