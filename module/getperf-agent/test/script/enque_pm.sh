#!/bin/sh
mysql -u root cm << EOF
delete from site_queue1;
insert into site_queue1  (event, que_names, que_vals, created)
values ('deploySitePM', 'site_id|sitekey', '1|IZA5971', NOW());
EOF

