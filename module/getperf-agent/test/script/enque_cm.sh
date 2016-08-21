#!/bin/sh
mysql -u root cm << EOF
delete from site_queue;
insert into site_queue  (event, que_names, que_vals, created) 
values ('deploySite', 'site_id|sitekey', '1|IZA5971', NOW());
EOF

