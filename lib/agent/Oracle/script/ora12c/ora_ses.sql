SELECT /*+ INDEX (s) INDEX (w) INDEX(p) */
     s.SID,
     p.SPID,
     s.USERNAME,
     s.COMMAND,
     s.STATUS,
     s.PROGRAM,
     s.SQL_ADDRESS,
     s.SQL_HASH_VALUE,
     s.PREV_SQL_ADDR,
     s.PREV_HASH_VALUE,
     s.LAST_CALL_ET,
     to_char(s.LOGON_TIME,'MMDDHH24MISS'),
     w.EVENT,
     w.P1,
     w.P2,
     w.P3,
     w.WAIT_TIME,
     w.SECONDS_IN_WAIT
FROM V$SESSION s, V$SESSION_WAIT w, V$PROCESS p
WHERE s.SID = w.SID
AND p.addr = s.paddr
;
