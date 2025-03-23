#!/bin/bash
# Register the ip address in the zabbix agent configuration file
# 
# Modify 'conf/zabbix_agentd.conf' from 'conf/zabbix_agentd_src.conf'  
#    Server=127.0.0.1
#    ServerActive=127.0.0.1
#    ListenPort=10050
#    Hostname=__HOSTNAME__	# Conver lowercase, and trim domain suffix.

OSNAME=`uname`
PWD=`dirname $0`
PTUNE_HOME=`cd $PWD/../.. && pwd`
CONF=$PTUNE_HOME/conf
SCRIPT=$PTUNE_HOME/script

ZABBIX_AGENTD_CONF_SRC="$SCRIPT/zabbix/zabbix_agentd_src.conf"
ZABBIX_AGENTD_CONF_OUT="$PTUNE_HOME/zabbix_agentd.conf"

if [ ! -f $ZABBIX_AGENTD_CONF_SRC ]; then
	$ECHO "ERROR zabbix_agentd_src.conf not found"
	exit -1
fi

ZABBIX_INI_FILE=$PTUNE_HOME/network/zabbix.ini
ZABBIX_HOST=`perl -ne 'print $1 if ($_=~/^s*ZABBIX_HOST=\s*(.+?)\s*$/);' $ZABBIX_INI_FILE`

HOSTNAME=`hostname`
HOSTNAME=`echo $HOSTNAME | perl -ne '$_=~s/\..*//g; print lc'`
sed -e "s!__HOSTNAME__!$HOSTNAME!" -e "s!__ZABBIX_HOST__!$ZABBIX_HOST!" $ZABBIX_AGENTD_CONF_SRC > $ZABBIX_AGENTD_CONF_OUT

PTUNE_USER=`LANG=C ls -ld $PTUNE_HOME | perl -ne '@x=split(/\s+/,$_); print $x[2];'`
ZABBIX_AGENTD="$PTUNE_HOME/bin/zabbixagent"
sed -e "s!__PTUNE_HOME__!$PTUNE_HOME!" -e "s!__PTUNE_USER__!$PTUNE_USER!" ${ZABBIX_AGENTD} > $ZABBIX_AGENTD.tmp
if [ $? -eq 0 ]; then
	mv $ZABBIX_AGENTD.tmp $ZABBIX_AGENTD
	chmod 755 $ZABBIX_AGENTD
fi
