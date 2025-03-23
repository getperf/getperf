WITH BPMETRICS AS (
     SELECT METRIC_TIMESTAMP,DB_NAME,
            BP_NAME, 
            POOL_DATA_GBP_L_READS +
              POOL_INDEX_GBP_L_READS +
              POOL_XDA_GBP_L_READS 
            AS LOGICAL_READS, 
            POOL_DATA_GBP_P_READS + 
              POOL_INDEX_GBP_P_READS + 
              POOL_XDA_GBP_P_READS 
            AS PHYSICAL_READS,
            MEMBER 
     FROM SMC_V111.MON_GET_BUFFERPOOL_V AS METRICS
     WHERE 
     (
        METRIC_TIMESTAMP>={ts '2019-08-01 00:00:00'}
        and BP_NAME not like 'IBM%'
     )
     )
     SELECT 
            METRIC_TIMESTAMP,
            DB_NAME,
            BP_NAME,
            LOGICAL_READS,
            PHYSICAL_READS,
     CASE WHEN LOGICAL_READS > 0 
          THEN DEC(((
            FLOAT(LOGICAL_READS) - FLOAT(PHYSICAL_READS)) / 
            FLOAT(LOGICAL_READS)) 
            * 100,5,2) 
          ELSE NULL END AS HIT_RATIO,
          MEMBER
     FROM BPMETRICS
;
