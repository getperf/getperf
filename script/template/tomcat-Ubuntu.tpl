#!/bin/bash
#
# tomcat
#
# chkconfig:
# description:  Start up the Tomcat servlet engine.
 
# Source function library.
# /etc/init.d/functions
 
SHUTDOWN_WAIT=10
TOMCAT_USER=[% ws_tomcat_owner %]
CATALINA_HOME=[% ws_tomcat_dir %]

tomcat_pid() {
  echo `ps aux | grep $CATALINA_HOME | grep -v grep | awk '{ print $2 }'`
}
 
start() {
  pid=$(tomcat_pid)
  if [ -n "$pid" ]
     then
        echo "Tomcat is already running (pid: $pid)"
     else
        echo "Starting Tomcat"
        /bin/su -s /bin/bash $TOMCAT_USER $CATALINA_HOME/bin/startup.sh
   fi
 
   return 0
}
 
stop() {
 pid=$(tomcat_pid)
  if [ -n "$pid" ]
  then
 
  echo "Stoping Tomcat"
   /bin/su -s /bin/bash $TOMCAT_USER $CATALINA_HOME/bin/shutdown.sh
 
   echo -n "Waiting for processes to exit ["
   kwait=$SHUTDOWN_WAIT
    count=0;
    until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
    do
      echo -n ".";
      sleep 1
      count=`expr $count + 1`;
    done
    echo "Done]"
 
    if [ $count -gt $kwait ]
    then
      echo "Killing processes ($pid) which didn't stop after $SHUTDOWN_WAIT seconds"
      kill -9 $pid
    fi
  else
    echo "Tomcat is not running"
  fi
 
  return 0
}
 
status() {
  pid=$(tomcat_pid)
  if [ -n "$pid" ]
  then
    echo "Tomcat is running with pid: $pid"
  else
    echo "Tomcat is not running"
  fi
}
 
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
       status
       ;;
*)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
exit 0
