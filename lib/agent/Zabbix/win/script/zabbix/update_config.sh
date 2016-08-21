#!/bin/bash
# Register the ip address in the zabbix agent configuration file
# 
# Modify 'conf/zabbix_agentd.conf' from 'conf/zabbix_agentd_src.conf'  
#    Server=127.0.0.1
#    ServerActive=127.0.0.1
#    ListenPort=10050
#    Hostname=__HOSTNAME__	# Conver lowercase, and trim domain suffix.

OSNAME=`uname`
PTUNE_HOME=$(cd $(dirname $0)/../.. && pwd)
CONF=$PTUNE_HOME/conf
SCRIPT=$PTUNE_HOME/script

ECHO="/bin/echo"
if [ "$OSNAME" = "SunOS" ]; then
	ECHO="/usr/ucb/echo"
fi

ZABBIX_AGENTD_CONF_SRC="$SCRIPT/zabbix/zabbix_agentd_src.conf"
ZABBIX_AGENTD_CONF_OUT="$PTUNE_HOME/zabbix_agentd.conf"

if [ ! -f $ZABBIX_AGENTD_CONF_SRC ]; then
	$ECHO "ERROR zabbix_agentd_src.conf not found"
	exit -1
fi

HOSTNAME=`hostname`
HOSTNAME=`echo $HOSTNAME | perl -ne '$_=~s/\..*//g; print lc'`
$ECHO "Update zabbix_agentd.conf"
sed -e "s/__HOSTNAME__/$HOSTNAME/" $ZABBIX_AGENTD_CONF_SRC > $ZABBIX_AGENTD_CONF_OUT
