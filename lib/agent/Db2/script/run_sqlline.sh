#!/bin/bash
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
USAGE="Usage: $CMDNAME [-d url] [-u user] [-p pass] [-f sql_src] [-s sql_dir] [-o output] [-t interval] [-c cnt]"
SQLLINE="/usr/share/sqlline/bin/sqlline"

# Set default param
CWD=`dirname $0`
DIR=.
SID=
CNT=1
INTERVAL=10
USER=db2inst1
PASS=db2inst1
SQL=
OUT=/tmp/sqlline.txt
ERR=/dev/null

# Get command option
OPT=
while getopts d:u:p:s:f:o:t:c: OPT
do
    case $OPT in
    d)  URL=$OPTARG
        ;;
    u)  USER=$OPTARG
        ;;
    p)  PASS=$OPTARG
        ;;
    f)  SQL=$OPTARG
        ;;
    s)  DIR=$OPTARG
        ;;
    o)  OUT=$OPTARG
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


if [ ! -x ${SQLLINE} ]; then
    echo "File not fount: ${SQLLINE}"
    exit 1
fi

ORASQL="${CWD}/${DIR}/${SQL}"
if [ ! -f "${ORASQL}" ]; then
    echo "File not found: ${ORASQL}"
    exit 1
fi

ORACNT=1
while test ${ORACNT} -le ${CNT}
do
    # Sleep Interval
    if [ ${ORACNT} -ne ${CNT} ]; then
        sleep ${INTERVAL} &
    fi

    ${SQLLINE} -u "${URL}" -n "${USER}" -p "${PASS}" --autoResize=false --maxWidth=1000 --maxColumnWidth=100 --silent=true -log "${OUT}" --run="${ORASQL}" > /dev/null

    if [ 0 != $? ]; then
        echo "ERROR[sqlline] : ${ORASQL}"
        exit 1
    fi

    wait
    ORACNT=`expr ${ORACNT} + 1`
done
