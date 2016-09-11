#!/bin/bash
# This script run backup Getperf site data to target server.
#
# 1. Target server .
#   need to create the backup directory '/data/backup'
#
# 2. Sorce server
#   need to ssh access to the target server.
#   ssh-copy-id -i /root/.ssh/id_rsa.pub root@targer-server

GETPERF_HOME="/home/psadmin/getperf"

TARGET_HOST="192.168.10.3"
USER=root
PASS=mysqlpassword

(
	cd $GETPERF_HOME
	tar czf - ./config/site/ ./var/site/ | ssh $TARGET_HOST 'cat - > /backup/data/getperf_var_site.tar.gz'
)
(
	cd /
	tar czf - ./etc/getperf | ssh $TARGET_HOST 'cat - > /backup/data/getperf_etc.tar.gz'
)

# mysqldump command for MySQL Backup
(
	time mysqldump --user=${USER} --password=${PASS} \
	    --single-transaction --all-databases --quick --routines \
	    | ssh $TARGET_HOST 'cat > /backup/data/mysqldump.dmp'
)

# Percona XtraBackup command for MySQL Backup
# (
#    time innobackupex /var/lib/mysql/ --user ${USER} --password ${PASS} --stream=tar \
#       | ssh $TARGET_HOST 'cat - > /backup/data/xtrabackup.tar'
# )
