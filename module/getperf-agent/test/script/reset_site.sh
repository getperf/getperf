#!/bin/sh
HOST='maascacti01'
mysql -u root cm << EOF

update sites set deploy_flg=NULL where id = 1;

EOF
