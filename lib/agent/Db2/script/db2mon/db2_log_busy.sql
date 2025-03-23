SELECT MON_GET_TRANSACTION_LOG_S.DB_NAME, MON_GET_TRANSACTION_LOG_S.METRIC_TIMESTAMP, MON_GET_TRANSACTION_LOG_S.MEMBER, MON_GET_TRANSACTION_LOG_S.LOG_WRITES, MON_GET_TRANSACTION_LOG_S.LOG_WRITE_TIME/1000.0 LOG_WRITE_TIME, MON_GET_TRANSACTION_LOG_S.NUM_LOG_WRITE_IO
FROM SMC_V111.MON_GET_TRANSACTION_LOG_S MON_GET_TRANSACTION_LOG_S
WHERE (MON_GET_TRANSACTION_LOG_S.METRIC_TIMESTAMP>={ts '2019-08-01 00:00:00'})
;
