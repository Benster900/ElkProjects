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
	apt-get install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev git -y

	# NTP Time sync
	apt install ntp -y
	service ntp start 
	
elif [ -f /etc/redhat-release ]; then

	# Install dependencies
	yum install cmake make gcc gcc-c++ flex bison libpcap-devel openssl-devel python-devel swig zlib-devel git -y

	# NTP Time Sync
	yum install ntp ntpdate ntp-doc -y
	systemctl enable ntpd
	systemctl start ntpd
	ntpdate pool.ntp.org

fi

# Install Bro
cd /opt
git clone --recursive git://git.bro.org/bro
cd bro
./configure
make
make install
export PATH=/usr/local/bro/bin:$PATH

# Configure Bro
broInterface=$(ip a | grep '2:' | grep 'en' | awk '{print $2}' |rev | cut -c 2- | rev)
echo $broInterface
sed -i "s#interface=eth0#interface=$broInterface#g" /usr/local/bro/etc/node.cfg

# Start Bro 
/usr/local/bro/bin/broctl install
/usr/local/bro/bin/broctl start
/usr/local/bro/bin/broctl status

echo "Run the following: export PATH=/usr/local/bro/bin:$PATH"
