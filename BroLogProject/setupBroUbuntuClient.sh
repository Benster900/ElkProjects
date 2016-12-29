#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

sudo apt-get install cmake make gcc g++ flex bison libpcap-dev libssl-dev python-dev swig zlib1g-dev -y

cd /opt
git clone --recursive git://git.bro.org/bro
cd bro

./configure
make
make install

export PATH=/usr/local/bro/bin:$PATH

interface=$(ip a | grep mtu | awk '{ print $2 }' | grep eno | rev | cut -c 2- | rev)
sed -i 's/interface=eth0/interface='$interface'/g' /usr/local/bro/etc/node.cfg

/usr/local/bro/bin/broctl install
/usr/local/bro/bin/broctl start
