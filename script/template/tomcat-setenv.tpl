#!/bin/sh

GETPERF_HOME=[% getperf_home %]
GETPERF_WS_ROLE=[% getperf_ws_role %]

JAVA_OPTS="-server -Xms256M -Xmx256M -Dconfig.file=$GETPERF_HOME/config/getperf_site.json"
JAVA_OPTS="$JAVA_OPTS -DGETPERF_WS_ROLE=$GETPERF_WS_ROLE"

export JAVA_OPTS
