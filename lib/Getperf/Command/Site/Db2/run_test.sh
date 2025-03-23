#!/bin/bash

# Folgende EXPORT Variablen setzen:
#
#   DB2USER
#   DB2PWD
#   DB2DB
#   DB2SCHEMA
#
#
#   Parameter:
#
#       Anzahl Aufrufe tbsel
#       runId  -> künstliche ID zum Speichern der Ergebnisse
#
count=$1
runId=$2

mkdir -p ./tmp

for i in $( seq 1 $count) ; do
	echo "**** Starting $i of $count"
	tmpfile="./tmp/$runId.$( printf %04i $i)" 
	#./tbsel "$DB2DB" "$DB2SCHEMA" "$DB2USER" "$DB2PWD" | tee "$tmpfile" || exit 1
	stdbuf -o 0 bash -c "./tbsel \"$DB2DB\" \"$DB2SCHEMA\" \"$DB2USER\" \"$DB2PWD\"" | tee "$tmpfile" || exit 1
	#script -c "./tbsel "$DB2DB" "$DB2SCHEMA" "$DB2USER" "$DB2PWD" | tee "$tmpfile" 
done

ls -1 tmp/$runId.* | sort -n | xargs -I {} grep CSV-stat-per-1000 {} > $runId.csv

echo "Done generating $runId.csv"


