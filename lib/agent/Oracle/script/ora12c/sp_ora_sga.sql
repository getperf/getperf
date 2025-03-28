COL VALUE FORMAT 999,999,999,999,999
COL DATE FORMAT A19

VARIABLE DBID NUMBER
VARIABLE BID NUMBER
VARIABLE EID NUMBER
VARIABLE BTIME VARCHAR2(20)
VARIABLE ETIME VARCHAR2(20)
VARIABLE INTERVAL NUMBER


BEGIN
SELECT DBID,BID,EID,BTIME,ETIME,INTERVAL INTO :DBID,:BID,:EID,:BTIME,:ETIME,:INTERVAL
  FROM (SELECT DBID,LAG(SNAP_ID) OVER(ORDER BY STARTUP_TIME,SNAP_ID) BID,SNAP_ID EID,
               TO_CHAR(LAG(SNAP_TIME) OVER(ORDER BY STARTUP_TIME,SNAP_ID),'YYYY/MM/DD HH24:MI:SS') BTIME,
               TO_CHAR(SNAP_TIME,'YYYY/MM/DD HH24:MI:SS') ETIME,
               (SNAP_TIME - LAG(SNAP_TIME) OVER(ORDER BY STARTUP_TIME,SNAP_ID))*(24*3600) "INTERVAL"
          FROM STATS$SNAPSHOT
         ORDER BY STARTUP_TIME DESC,SNAP_ID DESC)
 WHERE ROWNUM = 1;
END;
/

COL DATE FORMAT A19

COL CURRENT_SIZE FORMAT 999,999,999,999,999
COL COMPONENT FORMAT A30
COL DATE FORMAT A19

SELECT :ETIME AS "DATE",INSTANCE_NUMBER INST_ID,COMPONENT,CURRENT_SIZE
FROM STATS$MEMORY_DYNAMIC_COMPS
WHERE DBID     = :DBID
AND SNAP_ID  = :EID
AND CURRENT_SIZE > 0
UNION
SELECT :ETIME AS "DATE",1,NAME,TO_NUMBER(VALUE)
FROM V$PARAMETER
WHERE NAME = 'sga_max_size'
ORDER BY 2,4 DESC;
