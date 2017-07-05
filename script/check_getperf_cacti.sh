#!/bin/bash

#================================================================
# check web server
#
# wget option
# -nv : no verbose
# -S  : print server response
# -t  : tries number
# -T  : timeout seconds
# --spider             : don't download anything.
# --http-user=USER     : set http user to USER.
# --http-password=PASS : set http password to PASS.
#
# grep option
# -c : only print a count of matching lines per FILE
#================================================================

# parameter
TRY=1
TIMEOUT=60
SITEID="site1"
OPT="--no-proxy -nv -S --spider -t $TRY -T $TIMEOUT"

check1=`wget $OPT http://localhost/$SITEID/ 2>&1|grep -c "200 OK"`

if [ $check1 = 0 ]
then
    echo "Failed to Cacti web server."
    exit 1
fi
