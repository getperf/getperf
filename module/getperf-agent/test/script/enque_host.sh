#!/bin/sh
mysql -u root cm << EOF
delete from host_queue;
/* 
insert into host_queue  (event, que_names, que_vals, created) 
values ('certHost', 'sitekey|host', 'IZA5971|maascacti01', NOW());
*/
insert into host_queue  (event, que_names, que_vals, created) 
values ('verifyHostUpdate', 'sitekey|host', 'IZA5971|maascacti01', NOW());
EOF
perl ~/perfstat/script/monHostCM.pl

