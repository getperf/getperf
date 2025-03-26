select 
    stmtid,
    stmt_exec_time/1000 as total_exec_time,
    num_exec_with_metrics as number_of_exec,
    (stmt_exec_time/1000)/num_exec_with_metrics as exec_time_per_sql,
    total_cpu_time/1000000 as total_cpu_time,
    (total_cpu_time/1000000)/num_exec_with_metrics as cpu_time_per_sql
from
    table(mon_get_pkg_cache_stmt( null, null, null, -2)) as t
where
    t.num_exec_with_metrics <> 0
and
    (stmt_exec_time/1000)/ num_exec_with_metrics >= 1
order by exec_time_per_sql desc
limit 40;
