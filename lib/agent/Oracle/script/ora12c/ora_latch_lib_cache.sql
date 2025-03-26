select /*+ LEADING(DBA_HIST_ACTIVE_SESS_HISTORY.ash DBA_HIST_ACTIVE_SESS_HISTORY.ash DBA_HIST_ACTIVE_SESS_HISTORY.sn) FULL(DBA_HIST_ACTIVE_SESS_HISTORY.ash) USE_HASH(DBA_HIST_ACTIVE_SESS_HISTORY.ash DBA_HIST_ACTIVE_SESS_HISTORY.ash) */
  to_char(sample_time,'YYYY/MM/DD HH24:MI:SS') AS "SAMPLE_TIME",
  sum(decode(event,'latch: library cache',1,'library cache: mutex X',1,'library cache: mutex S',1,0)) AS "latch_count",
  sum(decode(event,'enq: UL - contention',1,0)) AS "UL_count",
  count(*) "session_count"
 from DBA_HIST_ACTIVE_SESS_HISTORY
 where sample_time > systimestamp - 1/48
 group by instance_number, to_char(sample_time,'YYYY/MM/DD HH24:MI:SS')
order by 1
;
