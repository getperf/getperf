select 'use sqlrank' from dual;

SELECT
 concat('insert into URA_SQLTEXT_TAB values (',stmtid)||','''||
 to_char(LAST_METRICS_UPDATE,'YYYY-MM-DD HH24:MI:SS')||''','''||
 cast(STMT_TEXT as varchar(10240))
 ||''') ON DUPLICATE KEY UPDATE LAST_METRICS_UPDATE ='''||
 to_char(LAST_METRICS_UPDATE,'YYYY-MM-DD HH24:MI:SS')||''';'
FROM TABLE(MON_GET_PKG_CACHE_STMT (NULL, NULL, NULL, -2))
-- WHERE LAST_METRICS_UPDATE >= CURRENT TIMESTAMP - 15 minutes
order by stmtid , LAST_METRICS_UPDATE
;
