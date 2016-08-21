#!/bin/sh

CWD=`dirname $0`
LD_LIBRARY_PATH=$CWD:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

$CWD/_getperfsoap $1 $2 $3 $4 $5 $6 $7 $8 $9
