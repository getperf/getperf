#!/bin/sh

CWD=`dirname $0`
HOME="${CWD}/.."

USAGE="$0 {archive path}.zip"

ARCHIVE="$1"
if [ ! -f "${ARCHIVE}" ]; then
	echo "File not found: ${ARCHIVE}"
	exit 1
fi
if [ ! -d ${HOME} ]; then
	echo "Directory not found: ${HOME}"
	exit 1
fi

cd $HOME
unzip -o $ARCHIVE

if [ $? -eq 0 ]; then
	rm $ARCHIVE
	echo "Unarchive succeed!"
	echo  $'\n\n'
else
	echo "$0 failed."
	exit 1
fi

exit 0
