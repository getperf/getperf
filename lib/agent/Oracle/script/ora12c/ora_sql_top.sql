select
    /*+ ORDERED */
    to_char(s.SNAP_TIME, 'YYYY/MM/DD HH24:MI:SS') START_TIME,
    a.OLD_HASH_VALUE,
    a.EXECUTIONS,
    a.DISK_READS,
    a.BUFFER_GETS,
    a.ROWS_PROCESSED,
    a.CPU_TIME,
    a.ELAPSED_TIME,
    a.USER_IO_WAIT_TIME,
    a.MODULE
from
    (
        select
            LAG(a.SNAP_ID, 1) OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID) as START_ID,
            a.SNAP_ID END_ID,
            a.OLD_HASH_VALUE,
            a.EXECUTIONS         - LAG(a.EXECUTIONS, 1)        OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID) as EXECUTIONS,
            a.DISK_READS         - LAG(a.DISK_READS, 1)        OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID) as DISK_READS,
            a.BUFFER_GETS        - LAG(a.BUFFER_GETS, 1)       OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID) as BUFFER_GETS,
            a.ROWS_PROCESSED     - LAG(a.ROWS_PROCESSED, 1)    OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID) as ROWS_PROCESSED,
            (a.CPU_TIME          - LAG(a.CPU_TIME, 1)          OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID)) / 1000000 as CPU_TIME,
            (a.ELAPSED_TIME      - LAG(a.ELAPSED_TIME, 1)      OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID)) / 1000000 as ELAPSED_TIME,
            (a.USER_IO_WAIT_TIME - LAG(a.USER_IO_WAIT_TIME, 1) OVER(partition by a.OLD_HASH_VALUE ORDER BY a.OLD_HASH_VALUE, a.SNAP_ID)) / 1000000 as USER_IO_WAIT_TIME,
            a.MODULE
        from
            stats$sql_summary a,
            STATS$SNAPSHOT i
        where
            a.SNAP_ID      = i.SNAP_ID
        AND i.SNAP_LEVEL   = 7
        AND a.COMMAND_TYPE <> 47
    ) a,
    STATS$SNAPSHOT s,
    STATS$SNAPSHOT e
where
    a.START_ID = s.SNAP_ID
and a.END_ID   = e.SNAP_ID
and e.SNAP_ID = (
        select
            max(SNAP_ID)
        from
            STATS$SNAPSHOT
        where
            SNAP_LEVEL = 7
    )
and CPU_TIME     > 0
AND ELAPSED_TIME > 0
AND EXECUTIONS   > 0
order by
    CPU_TIME DESC
;

