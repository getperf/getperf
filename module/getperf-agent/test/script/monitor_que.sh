#!/bin/sh
HOST='maascacti01'
mysql -u root cm << EOF
select * from host_queue;
select * from site_queue;
select * from site_queue1;
EOF
