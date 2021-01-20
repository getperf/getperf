#!/bin/bash
#
# Apache AXIS2 Webservice install
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

export GRADLE_HOME=/usr/local/gradle/latest
export PATH=$PATH:$GRADLE_HOME/bin
export JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF8
export CATALINA_HOME=$1
#export CATALINA_HOME=/usr/local/tomcat7-admin
export AXIS2_WS_HOME="$CWD/../module/getperf-ws"
export AXIS2_WS_MODULE=getperf-ws-1.0.0-all.jar
export WARFILE="$AXIS2_WS_HOME/build/libs/$AXIS2_WS_MODULE"
# ./script/../module/getperf-ws/build/libs/getperf-ws-1.0.0.jar
export WARFILE_DEST=$CATALINA_HOME/webapps/axis2/WEB-INF/services

#if [ ! -f $WARFILE ]; then
	cd $AXIS2_WS_HOME
	gradle axisJar
	gradle shadowJar
	if [ $? -ne 0 ]; then
        echo "gradle error. please cehck ; " 1>&2
        echo "'cd $AXIS2_WS_HOME; gradle axisJar; gradle jar'" 1>&2
        exit 1
	fi
#fi

sudo cp -p $WARFILE $WARFILE_DEST
