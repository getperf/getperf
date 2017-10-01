select name ,value 
from v$parameter
union all
select name ,value from v$diag_info
;
