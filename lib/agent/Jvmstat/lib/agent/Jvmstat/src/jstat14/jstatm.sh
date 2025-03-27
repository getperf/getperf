#!/bin/sh

BASEDIR=`dirname $0`; export BASEDIR
TARGET_DIR="${BASEDIR}/lib/"; export TARGET_DIR

CLASSPATH=
for name in `find "${TARGET_DIR}" -name *.jar 2> /dev/null`; do
	CLASSPATH=$CLASSPATH:$name
done
export CLASSPATH

java JStatm $1 $2 $3 $4 $5

