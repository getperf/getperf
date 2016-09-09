#!/bin/bash
# This script run backup MySQL data to target server.
#
# 1. Target server .
#   need to create the backup directory '/data/backup'
#
# 2. Sorce server
#   need to ssh access to the target server.
#   ssh-copy-id -i /root/.ssh/id_rsa.pub root@targer-server

TARGET_HOST="192.168.10.1"
USER=root
PASS=

time mysqldump --user=${USER} --password=${PASS} \
    --single-transaction --all-databases --quick --routines \
    | ssh $TARGET_HOST 'cat > /data/backup/mysqldump.dmp'
