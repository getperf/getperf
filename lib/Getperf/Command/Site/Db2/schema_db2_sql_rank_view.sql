DROP VIEW IF EXISTS `db2_sql_rank_summary`;
CREATE VIEW `db2_sql_rank_summary` as
select
    stmtid,
    member,
    from_unixtime(clock) as TIME_STAMP,
    (select value from db2_sql_rank where metric='NUM_EXEC_WITH_METRICS'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as NUM_EXEC_WITH_METRICS,
    (select value from db2_sql_rank where metric='STMT_EXEC_TIME'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as STMT_EXEC_TIME,
    (select value from db2_sql_rank where metric='TOTAL_CPU_TIME'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as TOTAL_CPU_TIME,
    (select value from db2_sql_rank where metric='TOTAL_ACT_WAIT_TIME'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as TOTAL_ACT_WAIT_TIME,
    (select value from db2_sql_rank where metric='LOCK_WAIT_TIME'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as LOCK_WAIT_TIME,
    (select value from db2_sql_rank where metric='LOCK_WAITS'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as LOCK_WAITS,
    (select value from db2_sql_rank where metric='DIRECT_READ_TIME'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as DIRECT_READ_TIME,
    (select value from db2_sql_rank where metric='DIRECT_WRITE_TIME'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as DIRECT_WRITE_TIME,
    (select value from db2_sql_rank where metric='ROWS_MODIFIED'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as ROWS_MODIFIED,
    (select value from db2_sql_rank where metric='ROWS_READ'
        and member = v.member 
        and package_schema = v.package_schema
        and package_name = v.package_name 
        and effective_isolation = v.effective_isolation
        and planid = v.planid
        and stmtid = v.stmtid and clock = v.clock) as ROWS_READ
from 
    db2_sql_rank v
group by
    stmtid,
    member,
    TIME_STAMP
;

alter table db2_sql_rank add index (stmtid, member, metric, clock);
