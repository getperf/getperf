#!/bin/bash
#
# Influx DB installation 
#

curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

sudo apt-get -y update && sudo apt-get -y install influxdb
# sudo service influxdb start
