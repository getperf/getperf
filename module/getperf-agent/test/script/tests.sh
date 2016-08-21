#!/bin/sh

SITE_HOME="${HOME}/conf/IZA5971/moi"
GP_HOME="${HOME}/work/getperf-ws-2.5.0/client
GP_TEST_HOME="${GP_HOME}

cp ${GP_HOME}/src/getperf ${GP_HOME}/bin
cp ${GP_HOME}/src/setup ${GP_HOME}/bin

sleep 1
$srcdir/test_common -s config -t 1
#${GP_TEST_HOME}/reset_dat.sh
#${GP_HOME}/build/ptune/bin/setup
#${GP_HOME}/build/ptune/bin/getperf
