select name,sum(bytes) "BYTES" from(
select
decode(NAME,'sql area','sql area',
'free memory','free memory',
'CCursor','CCursor',
'PCursor','PCursor',
'library cache','library cache','MISC') "NAME",
BYTES
from v$sgastat
where pool = 'shared pool'
and name <> 'ktcmvcb')
group by name
;
