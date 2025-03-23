DROP VIEW IF EXISTS `db2_sql_rank_summary`;
CREATE VIEW `db2_sql_rank_summary` as
select
    stmtid,
    member,
    from_unixtime(clock) as TIME_STAMP,
    (select value from db2_sql_rank where metric='NUM_EXEC_WITH_METRICS'
        and member = v.member 
        and stmtid = v.stmtid and clock = v.clock) as NUM_EXEC_WITH_METRICS,
    (select value from db2_sql_rank where metric='ROWS_READ'
        and member = v.member 
        and stmtid = v.stmtid and clock = v.clock) as ROWS_READ
from 
    db2_sql_rank v
group by
    stmtid,
    member,
    TIME_STAMP
;

alter table db2_sql_rank add index (stmtid, member, clock);
