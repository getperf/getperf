#!/bin/sh

CWD=`dirname $0`
LD_LIBRARY_PATH=$CWD/../bin:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

$CWD/_logretrieve $1 $2 $3 $4 $5 $6 $7 $8 $9
