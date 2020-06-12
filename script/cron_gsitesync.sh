#!/bin/sh
SITE_HOME=$HOME/work/site1
GETPERF_HOME=$HOME/getperf
RSYNC_URL=rsync://192.168.0.15/archive_site1
(
cd $SITE_HOME
$GETPERF_HOME/script/gsitesync --store=./inventory --purge $RSYNC_URL
)
