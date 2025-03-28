SELECT MON_GET_DATABASE_S.METRIC_TIMESTAMP, MON_GET_DATABASE_S.DB_NAME, MON_GET_DATABASE_S.MEMBER, MON_GET_DATABASE_S.ROWS_READ, MON_GET_DATABASE_S.ROWS_RETURNED,
MON_GET_DATABASE_S.ROWS_READ/MON_GET_DATABASE_S.ROWS_RETURNED READ_SELECT_RATIO
FROM SMC_V111.MON_GET_DATABASE_S MON_GET_DATABASE_S
WHERE (MON_GET_DATABASE_S.METRIC_TIMESTAMP>={ts '2019-08-01 00:00:00'})
ORDER BY MON_GET_DATABASE_S.METRIC_TIMESTAMP, MON_GET_DATABASE_S.DB_NAME, MON_GET_DATABASE_S.MEMBER
;
