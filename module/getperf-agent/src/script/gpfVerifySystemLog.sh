#!/bin/sh

CWD=`dirname $0`
CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [output]"

OUT_DIR="$1"

# ログファイルの有無確認
LOGS=""
targets="messages secure syslog auth.log"
for target in $targets; do
	if [ -f "/var/log/${target}" ]; then
		if [ "$LOGS" = "" ]; then
			LOGS="/var/log/${target}"
		else
			LOGS="${LOGS},/var/log/${target}"
		fi
	fi
done

if [ $LOGS = "" ]; then
	echo "Log not found"
	exit 1
fi

$CWD/logretrieve -v -o "${OUT_DIR}" "${LOGS}"
if [ $? -eq 0 ]; then
	echo ${LOGS} > "${OUT_DIR}/syslog.lst"
	exit 0
else
	exit 1
fi

