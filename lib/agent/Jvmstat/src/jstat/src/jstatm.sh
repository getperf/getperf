#!/bin/sh

JAVA_HOME=/usr/lib/jvm/java; export JAVA_HOME
CLASSPATH=.:"${JAVA_HOME}/lib/tools.jar"; export CLASSPATH
BASEDIR=`dirname $0`; export BASEDIR
TARGET_DIR="${BASEDIR}/lib"; export TARGET_DIR

OLDIFS=${IFS}
IFS=''
for f in `find "${TARGET_DIR}" -name "*.jar" -o -name "*.ZIP" -o -name "*.zip" 2> /dev/null`
do
	if [ -f "$f" ]; then
		CLASSPATH=${CLASSPATH}:"$f"
fi
done
IFS=${OLDIFS}
$JAVA_HOME/bin/java JStatm $1 $2 $3 $4 $5 $6 $7 $8 $9

