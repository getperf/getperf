#!/bin/sh
# EDITOR=vi crontab -e
# 0,5,10,15,20,25,30,35,40,45,50,55 * * * * (/home/psadmin/ptune/bin/getperf_monitor.sh 2>&1) &

CWD=`dirname $0`
LD_LIBRARY_PATH=$CWD:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

WK_DIR="${CWD}/../_wk"
PID_FILE="${WK_DIR}/_pid_getperf"
RUN_FLAG="${WK_DIR}/_running_flg"

PID=1
if [ -f "${PID_FILE}" ]; then
	PID=`cat ${PID_FILE}`
fi

#if [ -f "${RUN_FLAG}" ]; then
	 if [ ! -d "/proc/${PID}" ]; then
	 	${CWD}/getperfctl start
	 fi
#fi

#if [ -f "${RUN_FLAG}" ]; then
#    EXIST_AGENT=`ps $PID | grep _getperf | wc -l`
#    if [ "$EXIST_AGENT" = "0" ]; then
#        rm $PID_FILE
#        ${CWD}/getperfctl start
#    fi
#fi
