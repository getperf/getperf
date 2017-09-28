SELECT 
  * 
FROM 
( SELECT /*+ USE_NL(T) */
    TO_CHAR ( I.SNAP_TIME , 
      'YYYY/MM/DD HH24:MI:SS' ) TIME , 
    E.HASH_VALUE , 
    E.EXECUTIONS - 
    NVL ( S.EXECUTIONS , 0 ) EXECUTIONS , 
    E.DISK_READS - 
    NVL ( S.DISK_READS , 0 ) DISK_READS , 
    E.BUFFER_GETS - 
    NVL ( S.BUFFER_GETS , 0 ) BUFFER_GETS , 
    E.ROWS_PROCESSED - 
    NVL ( S.ROWS_PROCESSED , 0 ) ROWS_PROCESSED , 
    ( E.CPU_TIME - 
      NVL ( S.CPU_TIME , 0 ) ) /1000000 CPU_TIME , 
    ( E.ELAPSED_TIME - 
      NVL ( S.ELAPSED_TIME , 0 ) ) /1000000 ELAPSED_TIME , 
    UPPER ( SUBSTR ( LTRIM ( REPLACE( T.TEXT_SUBSET , CHR(13) ) , ' ' ) , 1 , 7 ) ) SQL , 
--    REGEXP_SUBSTR( UPPER ( T.TEXT_SUBSET ), 'SELECT|INSERT|UPDATE|DELETE' ) SQL,
    E.MODULE 
  FROM 
    STATS$SQL_SUMMARY E , 
    STATS$SQL_SUMMARY S , 
    STATS$SNAPSHOT I , 
    STATS$SQLTEXT T 
  WHERE 
    I.SNAP_ID = E.SNAP_ID 
    AND &STARTSNAP_ID = S.SNAP_ID ( + ) 
    AND E.HASH_VALUE = S.HASH_VALUE ( + ) 
--    AND E.HASH_VALUE = T.HASH_VALUE 
    AND T.PIECE = 0 
    AND E.DBID = S.DBID ( + ) 
    AND E.SQL_ID = T.SQL_ID
    AND E.SQL_ID = S.SQL_ID(+)
    AND E.INSTANCE_NUMBER = S.INSTANCE_NUMBER ( + ) 
    AND E.SNAP_ID = &ENDSNAP_ID ) 
WHERE 
  HASH_VALUE 
  IN (
    SELECT 
      HASH_VALUE 
    FROM 
      ( 
      SELECT 
        E.HASH_VALUE , 
        E.DISK_READS - 
        NVL ( S.DISK_READS , 0 ) DISK_READS 
      FROM 
        STATS$SQL_SUMMARY E , 
        STATS$SQL_SUMMARY S 
      WHERE 
        &STARTSNAP_ID = S.SNAP_ID ( + ) 
        AND E.HASH_VALUE = S.HASH_VALUE ( + ) 
        AND E.DBID = S.DBID ( + ) 
        AND E.INSTANCE_NUMBER = S.INSTANCE_NUMBER ( + ) 
        AND E.SNAP_ID = &ENDSNAP_ID 
      ORDER BY 
        DISK_READS 
        DESC ) 
    WHERE 
      ROWNUM < 101 
    UNION ALL 
    SELECT 
      HASH_VALUE 
    FROM 
      ( 
      SELECT 
        E.HASH_VALUE , 
        E.BUFFER_GETS - 
        NVL ( S.BUFFER_GETS , 0 ) BUFFER_GETS 
      FROM 
        STATS$SQL_SUMMARY E , 
        STATS$SQL_SUMMARY S 
      WHERE 
        &STARTSNAP_ID = S.SNAP_ID ( + ) 
        AND E.HASH_VALUE = S.HASH_VALUE ( + ) 
        AND E.DBID = S.DBID ( + ) 
        AND E.INSTANCE_NUMBER = S.INSTANCE_NUMBER ( + ) 
        AND E.SNAP_ID = &ENDSNAP_ID 
      ORDER BY 
        BUFFER_GETS 
        DESC ) 
    WHERE 
      ROWNUM < 101 
    UNION ALL 
    SELECT 
      HASH_VALUE 
    FROM 
      ( 
      SELECT 
        E.HASH_VALUE , 
        ( E.CPU_TIME - 
          NVL ( S.CPU_TIME , 0 ) ) /1000000 CPU_TIME 
      FROM 
        STATS$SQL_SUMMARY E , 
        STATS$SQL_SUMMARY S 
      WHERE 
        &STARTSNAP_ID = S.SNAP_ID ( + ) 
        AND E.HASH_VALUE = S.HASH_VALUE ( + ) 
        AND E.DBID = S.DBID ( + ) 
        AND E.INSTANCE_NUMBER = S.INSTANCE_NUMBER ( + ) 
        AND E.SNAP_ID = &ENDSNAP_ID 
      ORDER BY 
        CPU_TIME 
        DESC ) 
    WHERE 
      ROWNUM < 101 
  )  
;
