## Logstash

	sudo nano /etc/logstash/conf.d/bro-conn_log.conf
	sudo -u logstash /opt/logstash/bin/logstash -f /etc/logstash/conf.d/bro-conn_log.conf --debug
	sudo -u logstash /opt/logstash/bin/logstash agent -f /etc/logstash/conf.d/bro-conn_log.conf --configtest
	sudo -u logstash /opt/logstash/bin/logstash agent -f /etc/logstash/conf.d --configtest

## Bro

	tail -f /nsm/bro/logs/current/conn.log

## Print out bro log headers

	cd /nsm/bro/logs/current/
	grep -E "^#fields" *.log

## Pull down conf files

	cd /etc/logstash/conf.d/
