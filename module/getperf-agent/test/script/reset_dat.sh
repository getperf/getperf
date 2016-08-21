#!/bin/sh
HOST='maascacti01'
mysql -u root cm << EOF

delete from hosts where hostname = 'moi';
EOF
