#!/bin/bash
#
# Initialize script & log file access role
#

LANG=C;export LANG
CWD=`dirname $0`

chmod 700 $CWD/config-pkg.pl
chmod 700 $CWD/cre_config.pl
# chmod 700 $CWD/deploy-ssl.sh
chmod 700 $CWD/deploy-ws.pl
chmod 700 $CWD/gradle-install.sh
chmod 700 $CWD/mysql-setup.sh
chmod 700 $CWD/ssladmin.pl

chmod 755 $CWD/domain.pl
chmod 755 $CWD/initsite.pl
chmod 755 $CWD/profile.sh
#chmod 755 $CWD/rsync.pl
chmod 644 $CWD/sumup.pl
chmod 755 $CWD/sumup

