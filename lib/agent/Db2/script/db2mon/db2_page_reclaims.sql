SELECT MON_GET_PAGE_ACCESS_INFO_S.DB_NAME, MON_GET_PAGE_ACCESS_INFO_S.METRIC_TIMESTAMP, MON_GET_PAGE_ACCESS_INFO_S.TABSCHEMA, MON_GET_PAGE_ACCESS_INFO_S.OBJTYPE, Sum(MON_GET_PAGE_ACCESS_INFO_S.PAGE_RECLAIMS_X) AS """PAGE_RECLAIMS_X""", Sum(MON_GET_PAGE_ACCESS_INFO_S.SPACEMAPPAGE_PAGE_RECLAIMS_X) AS """SPACEMAPPAGE_PAGE_RECLAIMS_X""", Sum(MON_GET_PAGE_ACCESS_INFO_S.RECLAIM_WAIT_TIME) AS """RECLAIM_WAIT_TIME"""
FROM SMC_V111.MON_GET_PAGE_ACCESS_INFO_S MON_GET_PAGE_ACCESS_INFO_S
GROUP BY MON_GET_PAGE_ACCESS_INFO_S.DB_NAME, MON_GET_PAGE_ACCESS_INFO_S.METRIC_TIMESTAMP, MON_GET_PAGE_ACCESS_INFO_S.TABSCHEMA, MON_GET_PAGE_ACCESS_INFO_S.OBJTYPE
HAVING (MON_GET_PAGE_ACCESS_INFO_S.METRIC_TIMESTAMP>={ts '2019-08-01 00:00:00'})
;
