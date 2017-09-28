#!/bin/sh
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

# Set Oracle environment
if [ ! -f ${CWD}/oracle_env ]; then
    echo "File not fount: ${CWD}/oracle_env"
    exit 1
fi
. ${CWD}/oracle_env

SQLPLUS="${ORACLE_HOME}/bin/sqlplus"

if [ ! -x ${SQLPLUS} ]; then
	echo "File not fount: ${SQLPLUS}"
	exit 1
fi

${SQLPLUS} -s ${USER} << EOF1 2>&1
set line 1000
WHENEVER SQLERROR EXIT 1;
EXEC DBMS_STATS.GATHER_SCHEMA_STATS(OWNNAME => 'PERFSTAT',NO_INVALIDATE => FALSE,CASCADE=>TRUE);
EOF1
if [ 0 != $? ]; then
  echo "ERROR[sqlplus] : EXEC DBMS_STATS.GATHER_SCHEMA_STATS"
  exit 1
fi

exit 0
