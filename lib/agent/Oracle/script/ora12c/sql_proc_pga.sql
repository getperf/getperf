select * from (
select
    to_char(SYSDATE, 'YYYY/MM/DD HH24:MI:SS') TIME,
    1 AS "INST_ID",
    PROGRAM,
    PGA_ALLOC_MEM
from
    v$process
order by 4 DESC
) where rownum < 11
;

