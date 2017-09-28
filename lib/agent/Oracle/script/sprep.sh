#!/bin/bash
#
# This procedure execute Oracle statspack snapshot and report.
#

LANG=C;export LANG
COLUMNS=160;export COLUMNS
#resize -s 100 160
CMDNAME=`basename $0`

# Set default param
# CWD=`dirname $0`
CWD=$(cd $(dirname $0) && pwd)
MODE=DEFAULT
USER=perfstat/perfstat
PURGE=YES
PURGE_LEVEL=0
CATEGORY="ORACLE"
SCRIPT="ora12c"
SNAPSHOT_LEVEL=5
CHECK_PROCESS=YES

# Oracle RAC Option
# If there are Oracle RAC Enviroment, this parameter should set 1 or 2 or ... with each node
INSTANCE_NUM=1

LOG_DIR=.
SID=
ERR=

# Get command option
OPT=
while getopts sn:c:l:i:r:v:e:u:d:x OPT
do
    case $OPT in
    x) CHECK_PROCESS="NO"
        ;;
    s) MODE="RUNSNAP"
        ;;
    n) PURGE_LEVEL=$OPTARG
        ;;
    l) LOG_DIR=$OPTARG
        ;;
    i) SID=$OPTARG
        ;;
    r) INSTANCE_NUM=$OPTARG
        ;;
    v) SNAPSHOT_LEVEL=$OPTARG
        ;;
    u) USER=$OPTARG
        ;;
    c) CATEGORY=$OPTARG
        ;;
    e) ERR=$OPTARG
        ;;
    d) SCRIPT=$OPTARG
        ;;
    \?)
        echo "Usage" 1>&2
        echo "$CMDNAME [-s] [-n purgecnt] [-u user/pass[@tns]] [-c cat] [-i sid]" 1>&2
        echo "$USAGE           [-l dir] [-r instance_num] [-d ora12c]\n" 1>&2
        echo "$USAGE           [-v snaplevel] [-e err] [-d script] [-x]" 1>&2
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

# Execute snap of statspack
if [ "RUNSNAP" = "${MODE}" ]; then
    ${SQLPLUS} -s ${USER} << EOF1 > ${ERR} 2>&1
    WHENEVER SQLERROR EXIT 1;
    exec statspack.snap(i_snap_level=>${SNAPSHOT_LEVEL});
EOF1
    if [ 0 != $? ]; then
        echo "ERROR[sqlplus] : statspack.snap(i_snap_level=>${SNAPSHOT_LEVEL});"
        cat $ERR
    #    exit 1
    fi
fi

# Open "snpids" work file
NSNAPID=0
if [ -f ${WORK}/snapids_${CATEGORY}_${SID} ]; then
    exec 3<&0 < ${WORK}/snapids_${CATEGORY}_${SID}
    while read ID
    do
        NSNAPID=`expr $NSNAPID + 1`
        eval SNAP_$NSNAPID='"$ID"'
    done
fi
# Get old snap_id from "snapids" work file
eval OLD_ID=\$SNAP_$NSNAPID
if [ "${OLD_ID}" = "" ]; then
  OLD_ID=0
fi

# Get newest snap_id from Statspack
${SQLPLUS} -s ${USER} << EOF2 > ${ERR} 2>&1
WHENEVER SQLERROR EXIT 1;
spool ${WORK}/newid.$$
select 'NEWEST_SNAPID '||max(snap_id) snap_id from stats\$snapshot where INSTANCE_NUMBER=${INSTANCE_NUM};
spool off
EOF2
if [ 0 != $? ]; then
    echo "ERROR[sqlplus] : select max(snap_id) from stats\$snapshot where INSTANCE_NUMBER=${INSTANCE_NUM};"
    exit 1
fi
NEW_ID=`perl -ne 'print $1 if /^NEWEST_SNAPID (\d+)/' ${WORK}/newid.$$`
/bin/rm -f ${WORK}/newid*.$$
if [ "${NEW_ID}" = "" ]; then
    echo "newid not found."
    exit 0
fi


# If the old snapshot is larger than the new snapshot, remove the snapids file, and terminate
# This occurs when re-creating statspack
if [ "${OLD_ID}" -gt "${NEW_ID}" ]; then
    echo "ERROR : Snapshot if OLD_ID(=${OLD_ID}) > NEW_ID(=${NEW_ID}). Maybe Drop/Create Statspack"
    echo "delete snapids."
    rm ${WORK}/snapids_${CATEGORY}_${SID}
    exit 1
fi

# Report statspack
if [ 0 -lt "${NSNAPID}" -a "${OLD_ID}" -lt "${NEW_ID}" ]; then
    {
        cd ${ORACLE_HOME}/rdbms/admin
        ${SQLPLUS} -s ${USER} << EOF3 > ${ERR} 2>&1
        WHENEVER SQLERROR EXIT 1;
        define begin_snap=${OLD_ID}
        define end_snap=${NEW_ID}
        define report_name=${DIR}/spreport__${SID}
        @spreport
EOF3
    }
    if [ 0 != $? ]; then
        echo "ERROR[sqlplus] : ${CWD}/${SCRIPT}/spreport [${DIR}/spreport_${SID}] [${OLD_ID}..${NEW_ID}]"
        break 1
    fi

    # Report SQL Ranking when snapshot level >= 5
    if [ ${SNAPSHOT_LEVEL} -ge 5 ]; then
    {
        cd ${CWD}/${SCRIPT}
        ${SQLPLUS} -s ${USER} << EOF4 >> ${ERR} 2>&1
        SET ECHO OFF
        SET PAGESIZE 49999
        SET LINESIZE 5000
        SET HEADING ON
        SET UNDERLINE OFF
        SET VERIFY OFF
        SET FEEDBACK OFF
        SET TRIMSPOOL ON
        SET COLSEP '|'
        WHENEVER SQLERROR EXIT 1;
        DEF STARTSNAP_ID=${OLD_ID}
        DEF ENDSNAP_ID=${NEW_ID}
        SPOOL ${DIR}/ora_sql_top__${SID}
        @ora_sql_top
        SPOOL OFF
EOF4
    }
    fi

    # Report Object Ranking when snapshot level >= 7
    if [ ${SNAPSHOT_LEVEL} -ge 7 ]; then
    {
        cd ${CWD}/${SCRIPT}
        ${SQLPLUS} -s ${USER} << EOF5 >> ${ERR} 2>&1
        SET ECHO OFF
        SET PAGESIZE 49999
        SET LINESIZE 5000
        SET HEADING ON
        SET UNDERLINE OFF
        SET VERIFY OFF
        SET FEEDBACK OFF
        SET TRIMSPOOL ON
        SET COLSEP '|'
        WHENEVER SQLERROR EXIT 1;
        DEF STARTSNAP_ID=${OLD_ID}
        DEF ENDSNAP_ID=${NEW_ID}
        SPOOL ${DIR}/ora_obj_top__${SID}
        @ora_obj_top
        SPOOL OFF
EOF5
    }
fi
else
    echo "No newest snapshot report."
fi

# Purge snapshot
if [ 0 -lt $NSNAPID -a 0 -lt "${PURGE_LEVEL}" ]; then

    # Get oldest snap_id form Statspack
    ${SQLPLUS} -s ${USER} << EOF6 > ${ERR} 2>&1
    WHENEVER SQLERROR EXIT 1;
    spool ${WORK}/snapid.$$
    select 'SNAPID '||min(snap_id) snap_id from stats\$snapshot  where INSTANCE_NUMBER=${INSTANCE_NUM};
    spool off
EOF6

    if [ 0 != $? ]; then
        echo "ERROR[sqlplus] : select min(snap_id) snap_id from stats\$snapshot where INSTANCE_NUMBER=${INSTANCE_NUM}"
    fi
    OLDEST_ID=`perl -ne 'print $1 if /^SNAPID (\d+)/' ${WORK}/snapid.$$`
    /bin/rm -f ${WORK}/snapid.$$

    PURGEN=`expr $NSNAPID - $PURGE_LEVEL`
    eval PURGE_ID=\$SNAP_$PURGEN

    if [ "${OLDEST_ID}" -ge "${PURGE_ID}" ]; then
        echo "No target of purge snapshot."
    else
    {
        echo "Purge snapshot : ${OLDEST_ID}..${PURGE_ID} ."
        cd ${ORACLE_HOME}/rdbms/admin
        ${SQLPLUS} -s ${USER} << EOF7 > ${ERR} 2>&1
        WHENEVER SQLERROR EXIT 1;
        define losnapid=${OLDEST_ID}
        define hisnapid=${PURGE_ID}
        #@sppurge
        execute statspack.purge(i_begin_snap=>${OLDEST_ID}, i_end_snap=>${PURGE_ID}, i_extended_purge=>TRUE)

EOF7
    }
    if [ 0 != $? ]; then
        echo "ERROR[sqlplus] : sppurge [${OLDEST_ID} .. ${PURGE_ID}]"
        exit 1
    fi
fi
else
    echo "No purge snapshot id."
fi

# Flush "snpids" work file
ID=`expr $NSNAPID - 1000`
if [ 0 -gt "${ID}" ]; then
    ID=1
fi
if [ -f ${WORK}/snapids_${CATEGORY}_${SID}_tmp ]; then
    /bin/rm -f ${WORK}/snapids_${CATEGORY}_${SID}_tmp
    if [ 0 != $? ]; then
        echo "ERROR : /bin/rm -f ${WORK}/snapids_${CATEGORY}_${SID}_tmp"
        exit 1
    fi
fi

while [ ${ID} -le ${NSNAPID} ];
do
    eval TMP_ID=\$SNAP_$ID
    echo ${TMP_ID} >> ${WORK}/snapids_${CATEGORY}_${SID}_tmp
    ID=`expr $ID + 1`
done

if [ "${OLD_ID}" -lt "${NEW_ID}" ]; then
    echo $NEW_ID >> ${WORK}/snapids_${CATEGORY}_${SID}_tmp
fi
/bin/mv -f ${WORK}/snapids_${CATEGORY}_${SID}_tmp ${WORK}/snapids_${CATEGORY}_${SID}
if [ 0 != $? ]; then
    echo "ERROR : /bin/mv -f ${WORK}/snapids_${CATEGORY}_${SID}_tmp ${WORK}/snapids_${CATEGORY}_${SID}"
    exit 1
fi

exit 0
