#!/bin/sh

CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [-j JAVA_HOME] [-e jvmps command]"

JAVA_HOME="/usr/java/default"
JVMPS="/usr/java/default/bin/jps"
JVMPS_OPT="-v"
HOST=""

OPT=
while getopts j:e:o: OPT
do
        case $OPT in
        j)      JAVA_HOME="${OPTARG}"
                ;;
        e)      JVMPS="${OPTARG}"
                ;;
        o)      JVMPS_OPT="${OPTARG}"
                ;;
        \?)     echo "$USAGE" 1>&2
                exit 1
                ;;
        esac
done
shift `expr $OPTIND - 1`

export JAVA_HOME

"${JVMPS}" ${JVMPS_OPT}
