#!/bin/sh
#
# chkconfig: 35 85 15
# description: Getperf Sumup daemon

if [ -x [% getperf_home %]/script/sumupctl ];
then
    [% getperf_home %]/script/sumupctl $1
else
    echo "Required program [% getperf_home %]/script/sumupctl not found!"
    exit 1;
fi
