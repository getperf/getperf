select current timestamp as timestamp,t.* 
from table(mon_get_bufferpool(NULL, -1)) as t
;

