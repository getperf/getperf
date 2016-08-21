#!/bin/bash
#
# MySQL installation 
#

LANG=C;export LANG
CWD=`dirname $0`
CMDNAME=`basename $0`
USAGE="Usage: $CMDNAME [root password]"

# Check number of args
if [ $# -ne 1 ]; then
        echo "$USAGE" 1>&2
        exit 1
fi

MYSQL_ROOT_PASSWORD=$1

mysqladmin -u root password "$MYSQL_ROOT_PASSWORD"
if [ $? -ne 0 ]; then
    echo "MySQL password change is already running." 1>&2
    exit 1
fi

mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root'"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES"
