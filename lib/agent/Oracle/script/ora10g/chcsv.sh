#!/bin/sh
#
# This procedure execute Oracle statspack snap and report.
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
USAGE="Usage: $CMDNAME [-l dir] [-e errfile] [-i sid] [-u userid/passwd] [-f src] [-t interval] [-c cnt] [-x]"

# Set default param
CWD=`dirname $0`
DIR=.
SID=RTD
CNT=1
INTERVAL=10
USER=perfstat/perfstat
FILE=
ERR=/dev/null
CHECK_PROCESS=YES
SCRIPT="ora10g"

# Get command option
OPT=
while getopts l:e:i:u:f:c:t:d:x OPT
do
    case $OPT in
    x)  CHECK_PROCESS="NO"
        ;;
    l)  DIR=$OPTARG
        ;;
    e)  ERR=$OPTARG
        ;;
    i)  SID=$OPTARG
        ;;
    u)  USER=$OPTARG
        ;;
    f)  FILE=$OPTARG
        ;;
    c)  CNT=$OPTARG
        ;;
    t)  INTERVAL=$OPTARG
        ;;
    d)  SCRIPT=$OPTARG
        ;;
    \?) echo "$USAGE" 1>&2
        exit 1
        ;;
    esac
done
shift `expr $OPTIND - 1`
echo $SID

# Set current Date & Time
WORK="${CWD}/../_wk"

if [ ! -d ${WORK} ]; then
    /bin/mkdir -p ${WORK}
    if [ $? -ne 0 ]; then
        echo "Command failed."
        exit 1
    fi
fi

# --------- Set Oracle env --------------
if [ ! -f ${CWD}/${SCRIPT}/oracle_env ]; then
        echo "File not fount: ${CWD}/${SCRIPT}/oracle_env"
        exit 1
fi
. ${CWD}/${SCRIPT}/oracle_env

# Check Oracle process
if [ "YES" = "${CHECK_PROCESS}" ]; then
    ORACLE_SID=${SID}; export ORACLE_SID
    ORAPROC=`perl ${CWD}/hastat.pl`
    if [ 0 != $? ]; then
        echo "exec error : CHECK_PROCESS"
        exit 1
    fi
    if [ "${ORACLE_SID}" != "${ORAPROC}" ]; then
        echo "ORACLE(${ORACLE_SID}) not found."
        exit 1
    fi
fi

SQLPLUS="${ORACLE_HOME}/bin/sqlplus"
ORASQL="${CWD}/${SCRIPT}/${FILE}.sql"

if [ ! -x ${SQLPLUS} ]; then
	echo "File not fount: ${SQLPLUS}"
	exit 1
fi

if [ ! -f "${ORASQL}" ]; then
    echo "File not found: ${ORASQL}"
    exit 1
fi

ORARES="${WORK}/${FILE}_${SID}.$$"
ORAFILE="${DIR}/${FILE}__${SID}.txt"

if [ -f ${ORAFILE} ]; then
    /bin/rm -f $ORAFILE
fi


ORACNT=1
while test ${ORACNT} -le ${CNT}
do
    # Sleep Interval
    if [ ${ORACNT} -ne ${CNT} ]; then
        sleep ${INTERVAL} &
    fi

    # Exec ps command. 
    /bin/date '+Date:%y/%m/%d %H:%M:%S' >> ${ORAFILE}

    ${SQLPLUS} -s ${USER} << EOF1 >> ${ERR} 2>&1
    SET ECHO OFF
    SET PAGESIZE 49999
    SET HEADING ON
    SET UNDERLINE OFF
    SET LINESIZE 5000
    SET FEEDBACK OFF
    SET VERIFY OFF
    SET TRIMSPOOL ON
    SET COLSEP '|'
    WHENEVER SQLERROR EXIT 1;
    SPOOL ${ORARES}
    @${ORASQL}
    SPOOL OFF
EOF1

    if [ 0 != $? ]; then
        echo "ERROR[sqlplus] : ${ORASQL}"
        /bin/rm -f ${WORK}/*.$$
        exit 1
    fi

    cat ${ORAFILE} ${ORARES} >> chcsv_res.$$
    mv chcsv_res.$$ ${ORAFILE}

    wait
    ORACNT=`expr ${ORACNT} + 1`
done

/bin/rm -f ${WORK}/*.$$

exit 0
