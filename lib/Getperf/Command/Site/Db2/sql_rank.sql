select
MEMBER ||'|'||
SECTION_TYPE ||'|'||
min(to_char(INSERT_TIMESTAMP,'YYYY-MM-DD HH24:MI:SS')) ||'|'||
PACKAGE_SCHEMA ||'|'||
PACKAGE_NAME ||'|'||
EFFECTIVE_ISOLATION ||'|'||
sum(NUM_EXECUTIONS) ||'|'||
sum(NUM_EXEC_WITH_METRICS) ||'|'||
sum(PREP_TIME) ||'|'||
sum(TOTAL_ACT_TIME) ||'|'||
sum(TOTAL_ACT_WAIT_TIME) ||'|'||
sum(TOTAL_CPU_TIME) ||'|'||
sum(POOL_READ_TIME) ||'|'||
sum(POOL_WRITE_TIME) ||'|'||
sum(DIRECT_READ_TIME) ||'|'||
sum(DIRECT_WRITE_TIME) ||'|'||
sum(LOCK_WAIT_TIME) ||'|'||
sum(TOTAL_SECTION_SORT_TIME) ||'|'||
sum(TOTAL_SECTION_SORT_PROC_TIME) ||'|'||
-- sum(TOTAL_SECTION_SORTS) ||'|'||
sum(LOCK_ESCALS) ||'|'||
sum(LOCK_WAITS) ||'|'||
sum(ROWS_MODIFIED) ||'|'||
sum(ROWS_READ) ||'|'||
sum(ROWS_RETURNED) ||'|'||
sum(DIRECT_READS) ||'|'||
sum(DIRECT_READ_REQS) ||'|'||
sum(DIRECT_WRITES) ||'|'||
sum(DIRECT_WRITE_REQS) ||'|'||
sum(POOL_DATA_L_READS) ||'|'||
sum(POOL_TEMP_DATA_L_READS) ||'|'||
sum(POOL_XDA_L_READS) ||'|'||
sum(POOL_TEMP_XDA_L_READS) ||'|'||
sum(POOL_INDEX_L_READS) ||'|'||
sum(POOL_TEMP_INDEX_L_READS) ||'|'||
sum(POOL_DATA_P_READS) ||'|'||
sum(POOL_TEMP_DATA_P_READS) ||'|'||
sum(POOL_XDA_P_READS) ||'|'||
sum(POOL_TEMP_XDA_P_READS) ||'|'||
sum(POOL_INDEX_P_READS) ||'|'||
sum(POOL_TEMP_INDEX_P_READS) ||'|'||
sum(POOL_DATA_WRITES) ||'|'||
sum(POOL_XDA_WRITES) ||'|'||
sum(POOL_INDEX_WRITES) ||'|'||
sum(DEADLOCKS) ||'|'||
sum(FCM_RECV_WAIT_TIME) ||'|'||
sum(FCM_SEND_WAIT_TIME) ||'|'||
sum(LOCK_TIMEOUTS) ||'|'||
sum(LOG_BUFFER_WAIT_TIME) ||'|'||
sum(LOG_DISK_WAIT_TIME) ||'|'||
sum(LOG_DISK_WAITS_TOTAL) ||'|'||
max(to_char(LAST_METRICS_UPDATE,'YYYY-MM-DD HH24:MI:SS')) ||'|'||
sum(NUM_COORD_EXEC) ||'|'||
sum(NUM_COORD_EXEC_WITH_METRICS) ||'|'||
sum(TOTAL_ROUTINE_TIME) ||'|'||
STMT_TYPE_ID ||'|'||
sum(QUERY_COST_ESTIMATE) ||'|'||
sum(COORD_STMT_EXEC_TIME) ||'|'||
sum(STMT_EXEC_TIME) ||'|'||
sum(TOTAL_SECTION_TIME) ||'|'||
sum(TOTAL_SECTION_PROC_TIME) ||'|'||
sum(TOTAL_ROUTINE_NON_SECT_TIME) ||'|'||
sum(TOTAL_ROUTINE_NON_SECT_PROC_TIME) ||'|'||
sum(LOCK_WAITS_GLOBAL) ||'|'||
sum(LOCK_WAIT_TIME_GLOBAL) ||'|'||
sum(LOCK_TIMEOUTS_GLOBAL) ||'|'||
sum(LOCK_ESCALS_MAXLOCKS) ||'|'||
sum(LOCK_ESCALS_LOCKLIST) ||'|'||
sum(LOCK_ESCALS_GLOBAL) ||'|'||
sum(RECLAIM_WAIT_TIME) ||'|'||
sum(SPACEMAPPAGE_RECLAIM_WAIT_TIME) ||'|'||
sum(CF_WAITS) ||'|'||
sum(CF_WAIT_TIME ) ||'|'||
sum(POOL_DATA_GBP_L_READS) ||'|'||
sum(POOL_DATA_GBP_P_READS) ||'|'||
sum(POOL_DATA_LBP_PAGES_FOUND) ||'|'||
sum(POOL_DATA_GBP_INVALID_PAGES) ||'|'||
sum(POOL_INDEX_GBP_L_READS) ||'|'||
sum(POOL_INDEX_GBP_P_READS) ||'|'||
sum(POOL_INDEX_LBP_PAGES_FOUND ) ||'|'||
sum(POOL_INDEX_GBP_INVALID_PAGES) ||'|'||
sum(POOL_XDA_GBP_L_READS) ||'|'||
sum(POOL_XDA_GBP_P_READS) ||'|'||
sum(POOL_XDA_LBP_PAGES_FOUND) ||'|'||
sum(POOL_XDA_GBP_INVALID_PAGES) ||'|'||
-- sum(AUDIT_FILE_WRITE_WAIT_TIME) ||'|'||
-- sum(AUDIT_SUBSYSTEM_WAIT_TIME) ||'|'||
sum(DIAGLOG_WRITE_WAIT_TIME) ||'|'||
sum(FCM_MESSAGE_RECV_WAIT_TIME) ||'|'||
sum(FCM_MESSAGE_SEND_WAIT_TIME) ||'|'||
sum(FCM_TQ_RECV_WAIT_TIME) ||'|'||
sum(FCM_TQ_SEND_WAIT_TIME) ||'|'||
-- sum(EVMON_WAIT_TIME) ||'|'||
sum(TOTAL_EXTENDED_LATCH_WAIT_TIME) ||'|'||
sum(TOTAL_EXTENDED_LATCH_WAITS) ||'|'||
sum(MAX_COORD_STMT_EXEC_TIME) ||'|'||
-- sum(TOTAL_DISP_RUN_QUEUE_TIME) ||'|'||
-- sum(TOTAL_STATS_FABRICATION_TIME) ||'|'||
-- sum(TOTAL_SYNC_RUNSTATS_TIME) ||'|'||
sum(PREFETCH_WAIT_TIME) ||'|'||
sum(ROWS_DELETED) ||'|'||
sum(ROWS_INSERTED) ||'|'||
sum(ROWS_UPDATED) ||'|'||
STMTID ||'|'||
PLANID ||'|'||
sum(TOTAL_INDEX_BUILD_TIME) ||'|'||
sum(LOB_PREFETCH_WAIT_TIME) ||'|'||
sum(FED_ROWS_DELETED) ||'|'||
sum(FED_ROWS_INSERTED) ||'|'||
sum(FED_ROWS_UPDATED) ||'|'||
sum(FED_ROWS_READ) ||'|'||
sum(FED_WAIT_TIME) ||'|'||
sum(FED_WAITS_TOTAL) ||'|'||
to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')
from TABLE(MON_GET_PKG_CACHE_STMT (NULL, NULL, NULL, -2))
-- WHERE LAST_METRICS_UPDATE >= CURRENT TIMESTAMP - 15 minutes
group by MEMBER,SECTION_TYPE,PACKAGE_SCHEMA,PACKAGE_NAME,EFFECTIVE_ISOLATION,stmt_type_id,
         stmtid,planid,to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')
order by stmtid
;
