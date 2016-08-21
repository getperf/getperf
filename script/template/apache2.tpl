#!/bin/sh
#
# chkconfig: 35 85 15
# description: apache 2

apachectl="[% ws_apache_home %]/bin/apachectl"

case "$1" in
        start|stop|restart|fullstatus| \
        status|graceful|graceful-stop| \
        configtest|startssl)
            $apachectl $@
            ;;
        *)
            ;;
esac
