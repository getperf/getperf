#!/bin/sh
ERR=/dev/null

# Set Initial Parameter
LANG=C; export LANG
PATH=$PATH:`dirname $0`; export PATH
CMDNAME=`basename $0`
CWD=`dirname $0`
OUTDIR=.
USAGE="Usage: $CMDNAME [-r {rows}] [-l log]"

# Set default params
ROWS=60
OUT=busyratio.txt

# Set path
DT=`date '+%Y%m%d'`

LOG="null"
LOG1="/home/has/log/busyratio.log"
LOG2="/home/hasxm/log/busyratio.log"
LOG3="/home/siview/log/SMC/has/busyratio.${DT}.txt"
LOG4="/home/tsolperf/ptune/script/busyratio.${DT}.txt"

# Get command option
OPT=
while getopts r:l: OPT
do
    case $OPT in
    r) ROWS=$OPTARG
        ;;
    l) OUT=$OPTARG
        ;;
    \?) echo "$USAGE" 1>&2
        exit 1
        ;;
    esac
done
shift `expr $OPTIND - 1`

if [ -f ${LOG1} ]; then
	LOG=${LOG1}
elif [ -f ${LOG2} ]; then
	LOG=${LOG2}
elif [ -f ${LOG3} ]; then
	LOG=${LOG3}
elif [ -f ${LOG4} ]; then
	LOG=${LOG4}
fi

if [ "${LOG}" != "null" ]; then
	tail -${ROWS} ${LOG} > ${OUT}
fi

