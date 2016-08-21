#!/bin/bash
#
# Apache AXIS2 library install
#

LANG=C;export LANG
CWD=`dirname $0`
CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [tomcat home]"

# Check number of args
if [ $# -ne 1 ]; then
        echo "$USAGE" 1>&2
        exit 1
fi

export CATALINA_HOME=$1
#export CATALINA_HOME=/usr/local/tomcat7-admin
export AXIS2_VERSION="1.5.6"
export AXIS2_HOME="/tmp/rex/axis2-$AXIS2_VERSION"
export AXIS2_MODULE="axis2-$AXIS2_VERSION"
export WARFILE=$AXIS2_HOME/dist/axis2.war
export WARFILE_DEST=$CATALINA_HOME/webapps/axis2.war

if [ ! -d $AXIS2_HOME ]; then
#	export DOWNLOAD_SITE="http://ftp.jaist.ac.jp/pub/apache/axis/axis2/java/core"
	export DOWNLOAD_SITE="http://archive.apache.org/dist/axis/axis2/java/core/"

	cd /tmp/rex
	wget  "${DOWNLOAD_SITE}/${AXIS2_VERSION}/${AXIS2_MODULE}-bin.zip"
	unzip "${AXIS2_MODULE}-bin.zip"
fi

if [ ! -f $WARFILE ]; then
	cd $AXIS2_HOME/webapp
	ant
	if [ $? -ne 0 ]; then
        echo "ant error. please cehck 'cd $AXIS2_HOME/webapp; ant'" 1>&2
        exit 1
	fi
fi

cp -p $WARFILE $WARFILE_DEST

