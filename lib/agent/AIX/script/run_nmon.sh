#!/bin/sh
#
# This procedure execute database query using sqlline.
#
# Example:
# sh -x ./chcsv.sh -i TEST2 -l . -u system/manager -f oratbs
# $STATCMD{'ORACLE'} = join ( "\n",
#        '_pwd_/getorasql.sh -i RTD -l _odir_ -u perfstat/perfstat -f oratab',
#        '_pwd_/getorasql.sh -i RTD -l _odir_ -u perfstat/perfstat -f orases -t 300 -c 36',

LANG=C;export LANG
COLUMNS=160;export COLUMNS
#resize -s 100 160
CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [-t interval] [-c cnt] [-d output-dir]"

# Set default param
CWD=`dirname $0`
DIR=.
CNT=1
INTERVAL=10
ERR=/dev/null
NMON=/bin/nmon

# Get command option
OPT=
while getopts d:t:c: OPT
do
    case $OPT in
    d)  DIR=$OPTARG
        ;;
    c)  CNT=$OPTARG
        ;;
    t)  INTERVAL=$OPTARG
        ;;
    \?) echo "$USAGE" 1>&2
        exit 1
        ;;
    esac
done
shift `expr $OPTIND - 1`
echo $SID

SLEEP_TIME=`expr $CNT \* $INTERVAL + 30`

if [ ! -x ${NMON} ]; then
    echo "File not fount: ${NMON}"
    exit 1
fi

${NMON} -s "${INTERVAL}" -c "${CNT}" -m "${DIR}" -F nmon_base.csv > /dev/null

sleep $SLEEP_TIME
