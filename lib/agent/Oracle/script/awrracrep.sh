#!/bin/ksh
#
# This procedure execute Oracle statspack snap and report.
#
LANG=C;export LANG
COLUMNS=160;export COLUMNS
#resize -s 100 160
CMDNAME=`basename $0`

# Set default param
CWD=$(cd $(dirname $0) && pwd)
MODE=
USER=perfstat/perfstat
PURGE=YES
SCRIPT="ora10g"
SNAPSHOT_LEVEL=1
CHECK_PROCESS=YES

# Usage
# ./awrrep.sh -v 1 -d ora10g -l /tmp -i Y4VURA
# Oracle RAC Option
# If there are Oracle RAC Enviroment, this parameter should set 1 or 2 or ... with each node
INSTANCE_NUM=1

LOG_DIR=.
SID=
ERR=

# Get command option
OPT=
while getopts tsn:c:l:r:i:v:e:u:d:x OPT
do
	case $OPT in
	x)	CHECK_PROCESS="NO"
		;;
	s)	MODE="RUNSNAP"
		;;
	l)	LOG_DIR=$OPTARG
		;;
	i)	SID=$OPTARG
		;;
    r) INSTANCE_NUM=$OPTARG
        ;;
	v)	SNAPSHOT_LEVEL=$OPTARG
		;;
	u)	USER=$OPTARG
		;;
	e)	ERR=$OPTARG
		;;
	d)	SCRIPT=$OPTARG
		;;
    \?) echo "Usage" 1>&2
        echo "$CMDNAME [-u user/pass[@tns]] [-i sid]" 1>&2
        echo "$USAGE          [-l dir] [-d ora12c] [-v snaplevel] [-e err] [-x]" 1>&2
        exit 1
		;;
	esac
done
shift `expr $OPTIND - 1`

# Set current Date & Time
WORK="${CWD}/../_wk"

if [ ! -d ${WORK} ]; then
	/bin/mkdir -p ${WORK}
fi

# Set ErrorLog
if [ "" = "${ERR}" ]; then
    ERR="/dev/null"
fi

# Set Oracle environment
if [ ! -f ${CWD}/${SCRIPT}/oracle_env ]; then
    echo "File not fount: ${CWD}/${SCRIPT}/oracle_env"
    exit 1
fi
. ${CWD}/${SCRIPT}/oracle_env

SQLPLUS="${ORACLE_HOME}/bin/sqlplus"

if [ ! -x ${SQLPLUS} ]; then
	echo "File not fount: ${SQLPLUS}"
	exit 1
fi

DIR=$(cd $(dirname "${LOG_DIR}/tmp") && pwd)

CHCSV="${CWD}/${SCRIPT}/chcsv.sh"
if [ ! -x ${CHCSV} ]; then
	echo "File not fount: ${CHCSV}"
	exit 1
fi

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

# Get newest snap_id from Statspack
${SQLPLUS} -s ${USER} << EOF1 > ${ERR} 2>&1
set line 1000
WHENEVER SQLERROR EXIT 1;
spool ${WORK}/newid.$$
select 'R'||rownum||' '||SNAP_ID
from
	(select distinct SNAP_ID from DBA_HIST_SNAPSHOT
		where SNAP_LEVEL = ${SNAPSHOT_LEVEL}
		order by SNAP_ID desc)
where rownum <= 2 ;
spool off
EOF1
if [ 0 != $? ]; then
  echo "ERROR[sqlplus] : select max(snap_id) from stats\$snapshot where INSTANCE_NUMBER=${INSTANCE_NUM};"
  exit 1
fi
NEW_ID=`perl -ne 'print $1 if /^R1\s*(\d*)/' ${WORK}/newid.$$`
OLD_ID=`perl -ne 'print $1 if /^R2\s*(\d*)/' ${WORK}/newid.$$`

if [ "$NEW_ID" = "" ]; then
	echo "newid not found."
	exit 1
fi
if [ "$OLD_ID" = "" ]; then
	echo "oldid not found."
	exit 1
fi
/bin/rm -f ${WORK}/newid*.$$

echo "snap id : ${OLD_ID} - ${NEW_ID}"
# Report statspack
if [ 0 -lt "${NEW_ID}" -a "${OLD_ID}" -lt "${NEW_ID}" ]; then
	{
        cd ${ORACLE_HOME}/rdbms/admin
		${SQLPLUS} -s ${USER} << EOF2 > ${ERR} 2>&1
		WHENEVER SQLERROR EXIT 1;
		define report_type=text
		define num_days=1
		define begin_snap=${OLD_ID}
		define end_snap=${NEW_ID}
		define report_name=${DIR}/awrrpt_rac__${SID}
		@awrgrpt
EOF2
	}
	if [ 0 != $? ]; then
	  echo "ERROR[sqlplus] : ${ORACLE_HOME}/rdbms/admin [${OLD_ID}..${NEW_ID}]"
	  exit 1
	fi
else
	echo "No report snapshot id."
fi

exit 0
