select 
    stmtid,
    member,
    stmt_exec_time/1000 as total_exec_time,
    num_exec_with_metrics as number_of_exec,
    total_cpu_time/1000000 as total_cpu_time
from
    table(mon_get_pkg_cache_stmt( null, null, null, -2)) as t
where
    t.num_exec_with_metrics <> 0
;
