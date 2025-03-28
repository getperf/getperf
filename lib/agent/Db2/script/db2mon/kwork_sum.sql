select
sum(NUM_EXECUTIONS) NUM_EXECUTIONS,
sum(NUM_EXEC_WITH_METRICS) NUM_EXEC_WITH_METRICS,
sum(PREP_TIME) PREP_TIME,
sum(TOTAL_ACT_TIME) TOTAL_ACT_TIME,
sum(TOTAL_ACT_WAIT_TIME) TOTAL_ACT_WAIT_TIME,
sum(TOTAL_CPU_TIME) TOTAL_CPU_TIME,
sum(POOL_READ_TIME) POOL_READ_TIME,
sum(POOL_WRITE_TIME) POOL_WRITE_TIME,
sum(DIRECT_READ_TIME) DIRECT_READ_TIME,
sum(DIRECT_WRITE_TIME) DIRECT_WRITE_TIME,
sum(LOCK_WAIT_TIME) LOCK_WAIT_TIME,
sum(TOTAL_SECTION_SORT_TIME) TOTAL_SECTION_SORT_TIME,
sum(TOTAL_SECTION_SORT_PROC_TIME) TOTAL_SECTION_SORT_PROC_TIME,
sum(TOTAL_SECTION_SORTS) TOTAL_SECTION_SORTS,
sum(LOCK_ESCALS) LOCK_ESCALS,
sum(LOCK_WAITS) LOCK_WAITS,
sum(ROWS_MODIFIED) ROWS_MODIFIED,
sum(ROWS_READ) ROWS_READ,
sum(ROWS_RETURNED) ROWS_RETURNED,
sum(DIRECT_READS) DIRECT_READS,
sum(DIRECT_READ_REQS) DIRECT_READ_REQS,
sum(DIRECT_WRITES) DIRECT_WRITES,
sum(DIRECT_WRITE_REQS) DIRECT_WRITE_REQS,
sum(POOL_DATA_L_READS) POOL_DATA_L_READS,
sum(POOL_TEMP_DATA_L_READS) POOL_TEMP_DATA_L_READS,
sum(POOL_XDA_L_READS) POOL_XDA_L_READS,
sum(POOL_TEMP_XDA_L_READS) POOL_TEMP_XDA_L_READS,
sum(POOL_INDEX_L_READS) POOL_INDEX_L_READS,
sum(POOL_TEMP_INDEX_L_READS) POOL_TEMP_INDEX_L_READS,
sum(POOL_DATA_P_READS) POOL_DATA_P_READS,
sum(POOL_TEMP_DATA_P_READS) POOL_TEMP_DATA_P_READS,
sum(POOL_XDA_P_READS) POOL_XDA_P_READS,
sum(POOL_TEMP_XDA_P_READS) POOL_TEMP_XDA_P_READS,
sum(POOL_INDEX_P_READS) POOL_INDEX_P_READS,
sum(POOL_TEMP_INDEX_P_READS) POOL_TEMP_INDEX_P_READS,
sum(POOL_DATA_WRITES) POOL_DATA_WRITES,
sum(POOL_XDA_WRITES) POOL_XDA_WRITES,
sum(POOL_INDEX_WRITES) POOL_INDEX_WRITES,
sum(WLM_QUEUE_TIME_TOTAL) WLM_QUEUE_TIME_TOTAL,
sum(WLM_QUEUE_ASSIGNMENTS_TOTAL) WLM_QUEUE_ASSIGNMENTS_TOTAL,
sum(DEADLOCKS) DEADLOCKS,
sum(FCM_RECV_WAIT_TIME) FCM_RECV_WAIT_TIME,
sum(FCM_SEND_WAIT_TIME) FCM_SEND_WAIT_TIME,
sum(LOCK_TIMEOUTS) LOCK_TIMEOUTS,
sum(LOG_BUFFER_WAIT_TIME) LOG_BUFFER_WAIT_TIME,
sum(NUM_LOG_BUFFER_FULL) NUM_LOG_BUFFER_FULL,
sum(LOG_DISK_WAIT_TIME) LOG_DISK_WAIT_TIME,
sum(LOG_DISK_WAITS_TOTAL) LOG_DISK_WAITS_TOTAL,
sum(NUM_COORD_EXEC) NUM_COORD_EXEC,
sum(NUM_COORD_EXEC_WITH_METRICS) NUM_COORD_EXEC_WITH_METRICS,
sum(TOTAL_ROUTINE_TIME) TOTAL_ROUTINE_TIME,
sum(QUERY_COST_ESTIMATE) QUERY_COST_ESTIMATE,
sum(COORD_STMT_EXEC_TIME) COORD_STMT_EXEC_TIME,
sum(STMT_EXEC_TIME) STMT_EXEC_TIME,
sum(TOTAL_SECTION_TIME) TOTAL_SECTION_TIME,
sum(TOTAL_SECTION_PROC_TIME) TOTAL_SECTION_PROC_TIME,
sum(TOTAL_ROUTINE_NON_SECT_TIME) TOTAL_ROUTINE_NON_SECT_TIME,
sum(TOTAL_ROUTINE_NON_SECT_PROC_TIME) TOTAL_ROUTINE_NON_SECT_PROC_TIME,
sum(LOCK_WAITS_GLOBAL) LOCK_WAITS_GLOBAL,
sum(LOCK_WAIT_TIME_GLOBAL) LOCK_WAIT_TIME_GLOBAL,
sum(LOCK_TIMEOUTS_GLOBAL) LOCK_TIMEOUTS_GLOBAL,
sum(LOCK_ESCALS_MAXLOCKS) LOCK_ESCALS_MAXLOCKS,
sum(LOCK_ESCALS_LOCKLIST) LOCK_ESCALS_LOCKLIST,
sum(LOCK_ESCALS_GLOBAL) LOCK_ESCALS_GLOBAL,
sum(RECLAIM_WAIT_TIME) RECLAIM_WAIT_TIME,
sum(SPACEMAPPAGE_RECLAIM_WAIT_TIME) SPACEMAPPAGE_RECLAIM_WAIT_TIME,
sum(CF_WAITS) CF_WAITS,
sum(CF_WAIT_TIME) CF_WAIT_TIME,
sum(POOL_DATA_GBP_L_READS) POOL_DATA_GBP_L_READS,
sum(POOL_DATA_GBP_P_READS) POOL_DATA_GBP_P_READS,
sum(POOL_DATA_LBP_PAGES_FOUND) POOL_DATA_LBP_PAGES_FOUND,
sum(POOL_DATA_GBP_INVALID_PAGES) POOL_DATA_GBP_INVALID_PAGES,
sum(POOL_INDEX_GBP_L_READS) POOL_INDEX_GBP_L_READS,
sum(POOL_INDEX_GBP_P_READS) POOL_INDEX_GBP_P_READS,
sum(POOL_INDEX_LBP_PAGES_FOUND) POOL_INDEX_LBP_PAGES_FOUND,
sum(POOL_INDEX_GBP_INVALID_PAGES) POOL_INDEX_GBP_INVALID_PAGES,
sum(POOL_XDA_GBP_L_READS) POOL_XDA_GBP_L_READS,
sum(POOL_XDA_GBP_P_READS) POOL_XDA_GBP_P_READS,
sum(POOL_XDA_LBP_PAGES_FOUND) POOL_XDA_LBP_PAGES_FOUND,
sum(POOL_XDA_GBP_INVALID_PAGES) POOL_XDA_GBP_INVALID_PAGES,
sum(AUDIT_FILE_WRITE_WAIT_TIME) AUDIT_FILE_WRITE_WAIT_TIME,
sum(AUDIT_SUBSYSTEM_WAIT_TIME) AUDIT_SUBSYSTEM_WAIT_TIME,
sum(DIAGLOG_WRITE_WAIT_TIME) DIAGLOG_WRITE_WAIT_TIME,
sum(FCM_MESSAGE_RECV_WAIT_TIME) FCM_MESSAGE_RECV_WAIT_TIME,
sum(FCM_MESSAGE_SEND_WAIT_TIME) FCM_MESSAGE_SEND_WAIT_TIME,
sum(FCM_TQ_RECV_WAIT_TIME) FCM_TQ_RECV_WAIT_TIME,
sum(FCM_TQ_SEND_WAIT_TIME) FCM_TQ_SEND_WAIT_TIME,
sum(EVMON_WAIT_TIME) EVMON_WAIT_TIME,
sum(TOTAL_EXTENDED_LATCH_WAIT_TIME) TOTAL_EXTENDED_LATCH_WAIT_TIME,
sum(TOTAL_EXTENDED_LATCH_WAITS) TOTAL_EXTENDED_LATCH_WAITS,
sum(MAX_COORD_STMT_EXEC_TIME) MAX_COORD_STMT_EXEC_TIME,
sum(TOTAL_DISP_RUN_QUEUE_TIME) TOTAL_DISP_RUN_QUEUE_TIME,
sum(TOTAL_STATS_FABRICATION_TIME) TOTAL_STATS_FABRICATION_TIME,
sum(TOTAL_SYNC_RUNSTATS_TIME) TOTAL_SYNC_RUNSTATS_TIME,
sum(TOTAL_SYNC_RUNSTATS) TOTAL_SYNC_RUNSTATS,
sum(TQ_SORT_HEAP_REQUESTS) TQ_SORT_HEAP_REQUESTS,
sum(TQ_SORT_HEAP_REJECTIONS) TQ_SORT_HEAP_REJECTIONS,
sum(PREFETCH_WAIT_TIME) PREFETCH_WAIT_TIME,
sum(IDA_SEND_WAIT_TIME) IDA_SEND_WAIT_TIME,
sum(IDA_RECV_WAIT_TIME) IDA_RECV_WAIT_TIME,
sum(ROWS_DELETED) ROWS_DELETED,
sum(ROWS_INSERTED) ROWS_INSERTED,
sum(ROWS_UPDATED) ROWS_UPDATED,
sum(POOL_COL_L_READS) POOL_COL_L_READS,
sum(POOL_TEMP_COL_L_READS) POOL_TEMP_COL_L_READS,
sum(POOL_COL_P_READS) POOL_COL_P_READS,
sum(POOL_TEMP_COL_P_READS) POOL_TEMP_COL_P_READS,
sum(POOL_COL_WRITES) POOL_COL_WRITES,
sum(TOTAL_COL_TIME) TOTAL_COL_TIME,
sum(TOTAL_COL_PROC_TIME) TOTAL_COL_PROC_TIME,
sum(TOTAL_COL_EXECUTIONS) TOTAL_COL_EXECUTIONS,
sum(COMM_EXIT_WAIT_TIME) COMM_EXIT_WAIT_TIME,
sum(COMM_EXIT_WAITS) COMM_EXIT_WAITS,
sum(EXT_TABLE_RECV_WAIT_TIME) EXT_TABLE_RECV_WAIT_TIME,
sum(EXT_TABLE_SEND_WAIT_TIME) EXT_TABLE_SEND_WAIT_TIME,
sum(TOTAL_INDEX_BUILD_TIME) TOTAL_INDEX_BUILD_TIME,
sum(TOTAL_COL_SYNOPSIS_TIME) TOTAL_COL_SYNOPSIS_TIME,
sum(TOTAL_COL_SYNOPSIS_PROC_TIME) TOTAL_COL_SYNOPSIS_PROC_TIME,
sum(TOTAL_COL_SYNOPSIS_EXECUTIONS) TOTAL_COL_SYNOPSIS_EXECUTIONS,
sum(LOB_PREFETCH_WAIT_TIME) LOB_PREFETCH_WAIT_TIME,
sum(FED_ROWS_DELETED) FED_ROWS_DELETED,
sum(FED_ROWS_INSERTED) FED_ROWS_INSERTED,
sum(FED_ROWS_UPDATED) FED_ROWS_UPDATED,
sum(FED_ROWS_READ) FED_ROWS_READ,
sum(FED_WAIT_TIME) FED_WAIT_TIME,
sum(FED_WAITS_TOTAL) FED_WAITS_TOTAL
FROM TABLE(MON_GET_PKG_CACHE_STMT (NULL, NULL, NULL, -2))
;
