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

COL NAME FORMAT A40
COL POOL FORMAT A30
COL BYTES FORMAT 999,999,999,999,999
COL END_INTERVAL_TIME FORMAT A19
COL INST_ID FORMAT 9999999

SELECT :ETIME AS "DATE",INSTANCE_NUMBER INST_ID,NAME,BYTES
FROM STATS$SGASTAT
WHERE DBID    = :DBID
AND SNAP_ID = :EID
AND POOL    = 'shared pool'
ORDER BY 2,4 DESC;
