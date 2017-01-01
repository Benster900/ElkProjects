# Syslog collector for ELKstack
Resource Link: https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-centos-7

## 02-beats-input.conf
### Does NOT support SSL
This file is input for logstash.

## 10-syslog-filter.conf
This file takes in type syslog and runs a grok pattern on the data.

## 30-elasticsearch-output.conf
This file takes the output of the pattern above and enters data into elasticsearch based on date.

