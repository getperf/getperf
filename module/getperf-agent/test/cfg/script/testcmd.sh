#!/bin/sh

#
# This procedure gets memory usage by swap command. 
#

LANG=C;export LANG
COLUMNS=160;export COLUMNS
ERRFLAG=0
TIMEOUT=10
OUTFILE=

CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [-e] [-t sec] [-l out.txt]"

# Get command option
OPT=
while getopts et:l: OPT
do
    case $OPT in
    e) ERRFLAG=1
        ;;
    t) TIMEOUT=$OPTARG
        ;;
    l) OUTFILE=$OPTARG
        ;;
    \?) echo "$USAGE" 1>&2
        exit 1
        ;;
    esac
done
shift `expr $OPTIND - 1`

PSCNT=1
while test ${PSCNT} -le ${TIMEOUT}
do
	if [ "" != "${OUTFILE}" ]; then
		echo ${PSCNT} >> $OUTFILE
	else
		echo ${PSCNT}
	fi
	if [ ${PSCNT} -ne ${TIMEOUT} ]; then
		sleep 1
	fi

	PSCNT=`expr ${PSCNT} + 1`
done

if [ $ERRFLAG -eq 1 ]; then
	echo "error occured" > /dev/stderr
	exit 1
else
	exit 0
fi

