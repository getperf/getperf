#!/bin/bash
#
# Influx DB installation 
#

cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL \$releasever
baseurl = https://repos.influxdata.com/rhel/\$releasever/\$basearch/stable
enabled = 0
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo -E yum -y install --enablerepo=influxdb influxdb curl
