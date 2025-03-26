#!/bin/bash
#
# Startup script for the Tomcat Servlet Container
#
# chkconfig: 2345 35 65
# description: Tomcat is the servlet container that is used in the official \
#              Reference Implementation for the Java Servlet and JavaServer \
#              Pages technologies

TOMCAT_USER=[% ws_tomcat_owner %]
CATALINA_HOME=[% ws_tomcat_dir %]

# Source function library.
if [ -f /etc/init.d/functions ]; then
  . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
  . /etc/rc.d/init.d/functions
elif [ -f /lib/lsb/init-functions ] ; then
  . /lib/lsb/init-functions
else
  exit 0
fi
prog=tomcat

start() {
    echo -n $"Starting $prog: "
    daemon --user $TOMCAT_USER $CATALINA_HOME/bin/startup.sh > /dev/null
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        echo_success
    else
        echo_failure
    fi
    echo
    [ $RETVAL = 0 ] && touch /var/lock/subsys/$prog
    return $RETVAL
}
stop() {
    echo -n $"Stopping $prog: "
    daemon --user $TOMCAT_USER $CATALINA_HOME/bin/shutdown.sh > /dev/null
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        echo_success
    else
        echo_failure
    fi
    echo
    [ $RETVAL = 0 ] && rm -f /var/lock/subsys/$prog
    return $RETVAL
}

# See how we were called.
case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    INSTANCES=`ps --columns 512 -aef|grep java|grep tomcat|grep org.apache.catalina.startup.Bootstrap|wc -l`
    if [ $INSTANCES -eq 0 ]; then
        echo $prog is stopped
        RETVAL=3
    else
        if [ $INSTANCES -eq 1 ]; then
            echo $prog is running 1 instance...
        else
            echo $prog is running $INSTANCES instances...
        fi
        RETVAL=0
    fi
    ;;
  *)
    echo $"Usage: $prog {start|stop|restart|status|help}"
    exit 1
esac

exit $RETVAL
