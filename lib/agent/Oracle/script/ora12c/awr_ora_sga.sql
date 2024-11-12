COL VALUE FORMAT 999,999,999,999,999
COL DATE FORMAT A19

VARIABLE DBID NUMBER
VARIABLE BID NUMBER
VARIABLE EID NUMBER
VARIABLE BTIME VARCHAR2(20)
VARIABLE ETIME VARCHAR2(20)
VARIABLE INTERVAL NUMBER

BEGIN
SELECT DBID,BID,EID,
       TO_CHAR(BEGIN_INTERVAL_TIME,'YYYY/MM/DD HH24:MI:SS') BTIME,
       TO_CHAR(END_INTERVAL_TIME  ,'YYYY/MM/DD HH24:MI:SS') ETIME,
       EXTRACT(SECOND   FROM END_INTERVAL_TIME - BEGIN_INTERVAL_TIME) 
       + EXTRACT(MINUTE FROM END_INTERVAL_TIME - BEGIN_INTERVAL_TIME) * 60
       + EXTRACT(HOUR   FROM END_INTERVAL_TIME - BEGIN_INTERVAL_TIME) * 3600
       + EXTRACT(DAY    FROM END_INTERVAL_TIME - BEGIN_INTERVAL_TIME) * 86400 as "INTERVAL"
 INTO :DBID,:BID,:EID,:BTIME,:ETIME,:INTERVAL
  FROM (SELECT DISTINCT DBID,LAG(SNAP_ID) OVER(ORDER BY SNAP_ID) BID,SNAP_ID EID,
               MAX(BEGIN_INTERVAL_TIME) AS "BEGIN_INTERVAL_TIME",
               MAX(END_INTERVAL_TIME) AS "END_INTERVAL_TIME"
          FROM DBA_HIST_SNAPSHOT
         GROUP BY DBID,SNAP_ID
         ORDER BY SNAP_ID DESC)
 WHERE ROWNUM = 1;
END;
/


COL DATE FORMAT A19

COL CURRENT_SIZE FORMAT 999,999,999,999,999
COL COMPONENT FORMAT A30
COL DATE FORMAT A19

SELECT :ETIME AS "DATE",INSTANCE_NUMBER INST_ID,COMPONENT,CURRENT_SIZE
  FROM DBA_HIST_MEM_DYNAMIC_COMP
 WHERE DBID     = :DBID
   AND SNAP_ID  = :EID
   AND CURRENT_SIZE > 0
UNION
SELECT :ETIME AS "DATE",INST_ID,NAME,TO_NUMBER(VALUE)
  FROM GV$PARAMETER
 WHERE NAME = 'sga_max_size'
 ORDER BY 2,4 DESC;

