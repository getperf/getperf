set trimspool on
set lines 999
set pages 5000
set arraysize 5000
set echo off
set feedback off
SET NULL 'N/A'

VARIABLE DBID number
VARIABLE BID number
VARIABLE EID number

begin
select DBID,BID,EID INTO :DBID,:BID,:EID from (
select DBID,lag(snap_id) OVER(ORDER BY snap_id) BID
, snap_id EID from dba_hist_snapshot
where instance_number = 1
order by snap_id DESC)
where rownum = 1;
end;
/

col INST format 999
col INT format a4
col ELA format 999,990.99
col DBTIM format 999,990.99
col UP_TIME format 999,990.99
col ASESS format 999,990.99

col INSTANCE_NAME format a15
col HOST_NAME format a15
col STARTUP_TIME format a20
col BEGIN_SNAP_TIME format a20
col END_SNAP_TIME format a20
col VERSION format a20
col PLATFORM format a30

col BEGIN_LOAD format 990.9
col END_LOAD format 990.9
col PCT_BUSY format 990.9
col PCT_USER format 990.9
col PCT_SYS format 990.9
col PCT_WIO format 990.9
col PCT_IDL format 990.9


col IDLE_TIME format 999,999,990.9
col BUSY_TIME format 999,999,990.9
col TOTAL_TIME format 999,999,990.9

col MEM_B format 999,999,990

col DB_TIME format 999,999,990.9
col DB_CPU format 999,999,990.9
col SQLEXEC_TIME format 999,999,990.9
col PARSE_TIME format 999,990.9
col HPARSE_TIME format 999,990.9
col PLSQL_TIME format 999,990.9
col JAVA_TIME format 999,990.9
col BG_TIME format 999,999,990.9
col BG_CPU format 999,999,990.9

col INSTSTR format a4
col WC format a20
col NM format a70

col USR_IO format 999,999,990.9
col SYS_IO format 999,999,990.9
col OTHER format 999,999,990.9
col APPL format 999,999,990.9
col COMM format 999,999,990.9
col NETW format 999,999,990.9
col CONC format 999,999,990.9
col CONF format 999,999,990.9
col CLU format 999,999,990.9
col DBC format 999,999,990.9


col TWT format 999,999,999,990
col PCTTO format 990.9
col TTM format 999,999,990.99
col AVTM format 999,990.9
col PCTDBT format 990.99
col AVAVTM format 999,990.99
col MINTM format 999,990.99
col MAXTM format 999,990.99
col STDTM format 999,990.99


col SLR format 999,999,999,990
col PHYR format 999,999,999,990
col PHYW format 999,999,999,990
col RDOS format 999,999,999,990
col BLKC format 999,999,999,990
col UC format 999,999,999,990
col EC format 999,999,999,990
col PC format 999,999,999,990
col LC format 999,999,999,990
col TX format 999,999,999,990

col slr_ps format 999,999,999,990
col phyr_ps format 999,999,999,990
col phyw_ps format 999,999,999,990
col rdos_ps format 999,999,999,990
col blkc_ps format 999,999,999,990
col uc_ps format 999,999,999,990
col ec_ps format 999,999,999,990
col pc_ps format 999,999,999,990
col lc_ps format 999,999,999,990
col tps format 999,999,999,990

col CNT500B format 999,990
col WAIT500B format 990.9
col AV500B format 990.9
col SD500B format 990.9

col CNT8K format 999,990
col WAIT8K format 990.9
col AV8K format 990.9
col SD8K format 990.9


col TOT_BS format 999,999,990.9
col CACHE_BS format 999,999,990.9
col IPQ_BS format 999,999,990.9
col DLM_BS format 999,999,990.9
col PING_BS format 999,999,990.9
col MISC_BS format 999,999,990.9
col TOT_BR format 999,999,990.9
col CACHE_BR format 999,999,990.9
col IPQ_BR format 999,999,990.9
col DLM_BR format 999,999,990.9
col PING_BR format 999,999,990.9
col MISC_BR format 999,999,990.9

col TOT_BS_S format 999,990.9
col CACHE_BS_S format 999,990.9
col IPQ_BS_S format 999,990.9
col DLM_BS_S format 999,990.9
col PING_BS_S format 999,990.9
col MISC_BS_S format 999,990.9
col TOT_BR_S format 999,990.9
col CACHE_BR_S format 999,990.9
col IPQ_BR_S format 999,990.9
col DLM_BR_S format 999,990.9
col PING_BR_S format 999,990.9
col MISC_BR_S format 999,990.9



rem spool awrgrpt.out

prompt WORKLOAD REPOSITORY REPORT (RAC)
prompt 
prompt Database Instances Included In Report
REM SQL ID: 8nws4g3a0hrg1 Plan Hash: 1161922134

select e.instance_number AS INST
     , di.instance_name
     , di.host_name
     , to_char(e.startup_time,'DD-Mon-YY HH24:MI') startup_time
     , to_char(b.end_interval_time,'DD-Mon-YY HH24:MI') begin_snap_time
     , to_char(e.end_interval_time,'DD-Mon-YY HH24:MI') end_snap_time
     , di.version
     ,(cast(e.end_interval_time as date)
            -cast(b.end_interval_time as date))*24*60 ela
     , st.value/1000000/60  dbtim
     ,(cast(e.end_interval_time as date)
            -cast(e.startup_time as date))*24 up_time
     , (st.value/1000000)/
      ((cast(e.end_interval_time as date)
            -cast(b.end_interval_time as date))*24*3600) asess
     , NVL(platform_name, ' ') AS PLATFORM
  from 
  dba_hist_database_instance di
     , dba_hist_snapshot b
     , dba_hist_snapshot e
     , (select se.dbid
             , se.instance_number
             , ((se.value - nvl(sb.value,0)))  value
          from dba_hist_sys_time_model sb
             , dba_hist_sys_time_model se
         where se.dbid            = :dbid
           and sb.snap_id         = :bid
           and se.snap_id         = :eid
           and se.dbid            = sb.dbid
           and se.instance_number IN (1,2,3,4)
           and se.instance_number = sb.instance_number
           and se.stat_id         = sb.stat_id
           and se.stat_name       = sb.stat_name
           and se.stat_name       = 'DB time')  st
 where di.dbid            = b.dbid
   and di.instance_number IN (1,2,3,4)
   and di.instance_number = b.instance_number
   and di.startup_time    = b.startup_time
   and b.snap_id          = :bid
   and b.dbid             = e.dbid
   and b.instance_number  = e.instance_number
   and e.snap_id          = :eid
   and e.dbid             = st.dbid
   and e.instance_number  = st.instance_number
   and di.dbid            = :dbid
 order by di.dbid, e.instance_number;

prompt 
prompt OS Statistics By Instance
REM SQL ID: chg4gxw92dgh8 Plan Hash: 1757036243

select instance_number AS INST
     , num_cpus_b          num_cpus
     , num_cores_b         num_cores
     , num_socks_b         num_socks
     , load_b              begin_load
     , load_e              end_load
     , 100 * busy_time_v/(busy_time_v + idle_time_v)  pct_busy
     , 100 * user_time_v/(busy_time_v + idle_time_v)  pct_user
     , 100 * sys_time_v/(busy_time_v + idle_time_v)   pct_sys
     , 100 * wio_time_v/(busy_time_v + idle_time_v)   pct_wio
     , 100 * idle_time_v/(busy_time_v + idle_time_v)  pct_idl
     , busy_time_v/100                            busy_time
     , idle_time_v/100                            idle_time
     , (busy_time_v + idle_time_v)/100            total_time
     , mem_b/1048576 mem_b
     , case when num_cpus_b != num_cpus_e
            then num_cpus_e
            else null
       end             num_cpus_e
     , case when num_cores_b != num_cores_e
            then num_cores_e
            else null
       end           num_cores_e
     , case when num_socks_b != num_socks_e
            then num_socks_e
            else null
       end           num_socks_e
     , case when mem_b != mem_e
            then mem_e/1048576
            else null
       end           mem_e
  from ((select se.instance_number
             , se.stat_name
             , sb.value bval
             , se.value eval
             , (se.value - nvl(sb.value,0))  value
        from dba_hist_osstat sb
           , dba_hist_osstat se
         where se.dbid            = :dbid
           and sb.snap_id    (+)  = :bid
           and se.snap_id         = :eid
           and se.dbid            = sb.dbid            (+)
           and se.instance_number IN (1,2,3,4)
           and se.instance_number = sb.instance_number (+)
           and se.stat_id         = sb.stat_id         (+))
        pivot (sum(value) v, max(bval) b, max(eval) e
               for stat_name in (
               'NUM_CPUS'   num_cpus
              ,'NUM_CPU_CORES'   num_cores
              ,'NUM_CPU_SOCKETS' num_socks
              ,'LOAD'       load
              ,'BUSY_TIME'  busy_time
              ,'IDLE_TIME'  idle_time
              ,'USER_TIME'  user_time
              ,'SYS_TIME'   sys_time
              ,'IOWAIT_TIME' wio_time
              ,'PHYSICAL_MEMORY_BYTES'  mem)))
 order by instance_number;

prompt 
prompt Time Model
REM SQL ID: 639g0kvnrbyh5 Plan Hash: 2514540105

select instance_number AS INST
     , db_time/1000000                db_time
     , db_cpu/1000000                 db_cpu
     , sqlexec_time/1000000           sqlexec_time
     , parse_time/1000000             parse_time
     , hparse_time/1000000            hparse_time
     , (nvl(plsql_time,0) + nvl(plsql_comp,0)
        + nvl(plsql_inb,0))/1000000 plsql_time
     , java_time/1000000              java_time
     , bg_time/1000000                bg_time
     , bg_cpu/1000000                 bg_cpu
  from ((select se.instance_number
             , se.stat_name
             , ((se.value - nvl(sb.value,0)))  value
          from dba_hist_sys_time_model sb
             , dba_hist_sys_time_model se
         where se.dbid            = :dbid
           and sb.snap_id     (+) = :bid
           and se.snap_id         = :eid
           and se.dbid            = sb.dbid            (+)
           and se.instance_number IN (1,2,3,4)
           and se.instance_number = sb.instance_number (+)
           and se.stat_id         = sb.stat_id         (+))
         pivot (sum(value) for stat_name in (
           'DB time'                               db_time
          ,'DB CPU'                                 db_cpu
          ,'sql execute elapsed time'         sqlexec_time
          ,'parse time elapsed'                 parse_time
          ,'hard parse elapsed time'           hparse_time
          ,'PL/SQL execution elapsed time'      plsql_time
          ,'PL/SQL compilation elapsed time'    plsql_comp
          ,'inbound PL/SQL rpc elapsed time'     plsql_inb
          ,'Java execution elapsed time'         java_time
          ,'background elapsed time'               bg_time
          ,'background cpu time'                    bg_cpu)))
 order by instance_number;

select 'Sum' AS INT
     , sum(db_time)/1000000                db_time
     , sum(db_cpu)/1000000                 db_cpu
     , sum(sqlexec_time)/1000000           sqlexec_time
     , sum(parse_time)/1000000             parse_time
     , sum(hparse_time)/1000000            hparse_time
     , sum((nvl(plsql_time,0) + nvl(plsql_comp,0)
        + nvl(plsql_inb,0)))/1000000 plsql_time
     , sum(java_time)/1000000              java_time
     , sum(bg_time)/1000000                bg_time
     , sum(bg_cpu)/1000000                 bg_cpu
  from ((select se.instance_number
             , se.stat_name
             , ((se.value - nvl(sb.value,0)))  value
          from dba_hist_sys_time_model sb
             , dba_hist_sys_time_model se
         where se.dbid            = :dbid
           and sb.snap_id     (+) = :bid
           and se.snap_id         = :eid
           and se.dbid            = sb.dbid            (+)
           and se.instance_number IN (1,2,3,4)
           and se.instance_number = sb.instance_number (+)
           and se.stat_id         = sb.stat_id         (+))
         pivot (sum(value) for stat_name in (
           'DB time'                               db_time
          ,'DB CPU'                                 db_cpu
          ,'sql execute elapsed time'         sqlexec_time
          ,'parse time elapsed'                 parse_time
          ,'hard parse elapsed time'           hparse_time
          ,'PL/SQL execution elapsed time'      plsql_time
          ,'PL/SQL compilation elapsed time'    plsql_comp
          ,'inbound PL/SQL rpc elapsed time'     plsql_inb
          ,'Java execution elapsed time'         java_time
          ,'background elapsed time'               bg_time
          ,'background cpu time'                    bg_cpu)));

prompt
prompt Foreground Wait Classes
REM SQL ID: btzz7nphfj108 Plan Hash: 2850197645

select s.instance_number AS INST
     , usr_io/1000000  usr_io
     , sys_io/1000000  sys_io
     , other/1000000   other
     , appl/1000000    appl
     , comm/1000000    comm
     , netw/1000000    netw
     , conc/1000000    conc
     , conf/1000000    conf
     , clu/1000000     clu
     , dbc/1000000     dbc
     , dbt/1000000     db_time
  from (
    select * 
  from (
      select e.instance_number
           , e.wait_class    
  wait_class
           , sum(case when e.time_waited_micro_fg is not null   
                 then e.time_waited_micro_fg - nvl(b.time_waited_micro_fg,0)
                    else (e.time_waited_micro - nvl(b.time_waited_micro,0))
                          - greatest(0,(nvl(ebg.time_waited_micro,0)
                                      - nvl(bbg.time_waited_micro,0)))
             end)              twm
        from dba_hist_system_event b
           , dba_hist_system_event e
           , dba_hist_bg_event_summary bbg
           , dba_hist_bg_event_summary ebg
       where b.snap_id  (+) = :bid
         and e.snap_id      = :eid
         and bbg.snap_id (+) = :bid
         and ebg.snap_id (+) = :eid
         and e.dbid          = :dbid
         and e.dbid            = b.dbid (+)
         and e.instance_number IN (1,2,3,4)
         and e.instance_number = b.instance_number (+)
         and e.event_id        = b.event_id (+)
         and e.dbid            = ebg.dbid (+)
         and e.instance_number = ebg.instance_number (+)
         and e.event_id        = ebg.event_id (+)
         and e.dbid            = bbg.dbid (+)
         and e.instance_number = bbg.instance_number (+)
         and e.event_id        = bbg.event_id (+)
         and e.total_waits     > nvl(b.total_waits,0)
         and e.wait_class     <>  'Idle'
       group by e.wait_class, e.instance_number)
       pivot (sum(twm) for 
  wait_class in (
        'User I/O'             usr_io
      , 'System I/O'           sys_io
      , 'Other'                 other
      , 'Application'            appl
      , 'Commit'                 comm
      , 'Concurrency'            conc
      , 'Configuration'          conf
      , 'Network'                netw
      , 'Cluster'                 clu)) ) s
  , ((select e.instance_number
          , e.stat_name
          , (e.value - nvl(b.value,0))     value
      from dba_hist_sys_time_model e
         , dba_hist_sys_time_model b
     where e.dbid            = :dbid
       and e.dbid            = b.dbid             (+)
       and e.instance_number IN (1,2,3,4)
       and e.instance_number = b.instance_number  (+)
       and e.snap_id         = :eid
       and b.snap_id    (+)  = :bid    
       and e.stat_id         = b.stat_id          (+)
       and e.stat_name in ('DB time','DB CPU'))
     pivot (sum(value) for stat_name in (
            'DB time'         dbt
          , 'DB CPU'          dbc)) ) st
 where s.instance_number = st.instance_number
 order by s.instance_number;

select 'Sum' AS INT
     , sum(usr_io)/1000000  usr_io
     , sum(sys_io)/1000000  sys_io
     , sum(other)/1000000   other
     , sum(appl)/1000000    appl
     , sum(comm)/1000000    comm
     , sum(netw)/1000000    netw
     , sum(conc)/1000000    conc
     , sum(conf)/1000000    conf
     , sum(clu)/1000000     clu
     , sum(dbc)/1000000     dbc
     , sum(dbt)/1000000     db_time
  from (
    select * 
  from (
      select e.instance_number
           , e.wait_class    
  wait_class
           , sum(case when e.time_waited_micro_fg is not null   
                 then e.time_waited_micro_fg - nvl(b.time_waited_micro_fg,0)
                    else (e.time_waited_micro - nvl(b.time_waited_micro,0))
                          - greatest(0,(nvl(ebg.time_waited_micro,0)
                                      - nvl(bbg.time_waited_micro,0)))
             end)              twm
        from dba_hist_system_event b
           , dba_hist_system_event e
           , dba_hist_bg_event_summary bbg
           , dba_hist_bg_event_summary ebg
       where b.snap_id  (+) = :bid
         and e.snap_id      = :eid
         and bbg.snap_id (+) = :bid
         and ebg.snap_id (+) = :eid
         and e.dbid          = :dbid
         and e.dbid            = b.dbid (+)
         and e.instance_number IN (1,2,3,4)
         and e.instance_number = b.instance_number (+)
         and e.event_id        = b.event_id (+)
         and e.dbid            = ebg.dbid (+)
         and e.instance_number = ebg.instance_number (+)
         and e.event_id        = ebg.event_id (+)
         and e.dbid            = bbg.dbid (+)
         and e.instance_number = bbg.instance_number (+)
         and e.event_id        = bbg.event_id (+)
         and e.total_waits     > nvl(b.total_waits,0)
         and e.wait_class     <>  'Idle'
       group by e.wait_class, e.instance_number)
       pivot (sum(twm) for 
  wait_class in (
        'User I/O'             usr_io
      , 'System I/O'           sys_io
      , 'Other'                 other
      , 'Application'            appl
      , 'Commit'                 comm
      , 'Concurrency'            conc
      , 'Configuration'          conf
      , 'Network'                netw
      , 'Cluster'                 clu)) ) s
  , ((select e.instance_number
          , e.stat_name
          , (e.value - nvl(b.value,0))     value
      from dba_hist_sys_time_model e
         , dba_hist_sys_time_model b
     where e.dbid            = :dbid
       and e.dbid            = b.dbid             (+)
       and e.instance_number IN (1,2,3,4)
       and e.instance_number = b.instance_number  (+)
       and e.snap_id         = :eid
       and b.snap_id    (+)  = :bid    
       and e.stat_id         = b.stat_id          (+)
       and e.stat_name in ('DB time','DB CPU'))
     pivot (sum(value) for stat_name in (
            'DB time'         dbt
          , 'DB CPU'          dbc)) ) st
 where s.instance_number = st.instance_number;

prompt
prompt Top Timed Events
REM SQL ID: 11cj41w2873mm Plan Hash: 2114863239

select * from (
     select lpad(case when s.instance_number is null
             then  '*' else to_char(s.instance_number,'999') end,4) inststr
       , wc, nm, sum(twt) twt
       , case when sum(twt) = 0 then null else sum(tto)/sum(twt)*100 end pctto
       , sum(ttm)/1000000 ttm
       , case when sum(twt) = 0 then null else sum(ttm)/sum(twt)/1000 end avtm
       , case when sum(dbt) = 0 then null else sum(ttm)/sum(dbt)*100 end pctdbt
       , case when s.instance_number is null then avg(avtm) end  avavtm
       , case when s.instance_number is null then min(avtm) end   mintm
       , case when s.instance_number is null then max(avtm) end   maxtm
       , case when s.instance_number is null then stddev_samp(avtm) end stdtm
       , case when s.instance_number is null then count(*) end cnt
       , dense_rank() over (partition by s.instance_number                       
  order by sum(ttm) desc, sum(twt) desc)  rnk
  from (( /* select events per 
  instance */
            select e.event_name nm, e.wait_class wc, e.instance_number
                   , e.total_waits - nvl(b.total_waits,0) twt
                   , e.total_timeouts - nvl(b.total_timeouts,0) tto
                   , (e.time_waited_micro - nvl(b.time_waited_micro,0)) ttm
                   , case when (e.total_waits - nvl(b.total_waits,0) = 0)
                       then null
                       else (e.time_waited_micro - nvl(b.time_waited_micro,0))/
                               (e.total_waits - nvl(b.total_waits,0))/1000
                     end avtm
             from dba_hist_system_event e, dba_hist_system_event b
             where e.snap_id    = :eid
               and b.snap_id (+)= :bid
               and e.dbid       = :dbid
               and e.dbid       = b.dbid (+)
               and e.instance_number IN (1,2,3,4)
               and e.instance_number = b.instance_number  (+)
               and e.event_id   = b.event_id (+)
               and e.event_name = b.event_name (+)
               and e.wait_class <> 'Idle')
            union all
            ( /* select time for DB CPU */
              select se.stat_name  nm, null wc, 
  se.instance_number , null twt
                   , null tto, (se.value - nvl(sb.value,0)) ttm, null avtm
                from dba_hist_sys_time_model se , dba_hist_sys_time_model sb
               where se.snap_id         = :eid
                 and sb.snap_id  (+)    = :bid
                 and se.dbid            = :dbid
                 and se.dbid            = sb.dbid (+)
                 and se.instance_number IN (1,2,3,4)
                 and se.instance_number = sb.instance_number (+)
                 and se.stat_name       = 'DB CPU'
                 and se.stat_name       = sb.stat_name (+)
                 and se.stat_id         = sb.stat_id (+)))  s
    , (select e.instance_number , sum((e.value - nvl(b.value,0)))  dbt
         from dba_hist_sys_time_model b, dba_hist_sys_time_model e
        where e.dbid = :dbid
          and e.dbid = b.dbid (+)
          and e.instance_number IN (1,2,3,4)
          and e.instance_number = b.instance_number (+)
             and e.snap_id = :eid
          and b.snap_id (+) = :bid
          and b.stat_id (+) = e.stat_id
          and e.stat_name = 'DB time'
        group by e.instance_number) tm
   where s.instance_number = tm.instance_number
   group by wc, nm, rollup(s.instance_number))
 where rnk <= 100
 order by inststr, ttm desc, twt desc, nm;


prompt
prompt Top Timed Foreground Events
REM SQL ID: 29j3dbtqnv354 Plan Hash: 1211404064

select * from (
      select lpad(case when s.instance_number is null then  '*'
              else to_char(s.instance_number,'999') end,4) inststr
       , wc, nm, sum(twt) twt
       , case when sum(twt) = 0 then null else 
  sum(tto)/sum(twt)*100 end pctto
       , sum(ttm)/1000000 ttm
       , case when sum(twt) = 0 then null else sum(ttm)/sum(twt)/1000 end avtm
       , case when sum(dbt) = 0 then null else sum(ttm)/sum(dbt)*100 end pctdbt
       , case when s.instance_number is null then avg(avtm) end  avavtm
       , case when s.instance_number is null then min(avtm) end   mintm
       , case when s.instance_number is null then max(avtm) end   maxtm
       , case when s.instance_number is null then stddev_samp(avtm) end stdtm
       , case when s.instance_number is null then count(*) end      cnt
       , dense_rank() over (partition by s.instance_number
                       order by sum(ttm) desc, sum(twt) desc)  rnk
  from (  ( /* select events per instance */
        select e.event_name nm, e.wait_class wc, e.instance_number
             , e.total_waits - nvl(b.total_waits,0) twt
             , e.total_timeouts - nvl(b.total_timeouts,0) tto
             , (e.time_waited_micro - nvl(b.time_waited_micro,0)) ttm
             , case when (e.total_waits - nvl(b.total_waits,0) = 0)
              then null
                          else (e.time_waited_micro - nvl(b.time_waited_micro,0))/
                         (e.total_waits - nvl(b.total_waits,0))/1000  end avtm
       from dba_hist_bg_event_summary e, dba_hist_bg_event_summary b
       where e.snap_id         = :eid
         and b.snap_id (+)     = :bid
         and e.dbid            = :dbid
         and e.dbid            = b.dbid (+)
         and e.instance_number IN (1,2,3,4)
         and e.instance_number = b.instance_number (+)
         and e.event_id        = b.event_id (+)
         and e.event_name      = b.event_name (+)
         and e.wait_class     <> 'Idle'
      )
      union all
      ( /* select time for background CPU */
         select se.stat_name nm, null wc, se.instance_number, null twt,
             null tto, (se.value - nvl(sb.value,0)) ttm, null avtm
          from dba_hist_sys_time_model se, dba_hist_sys_time_model sb
         where se.snap_id         = :eid
           and sb.snap_id  (+)    = :bid
           and se.dbid            = :dbid
           and se.dbid            = sb.dbid (+)
           and se.instance_number IN (1,2,3,4)
           and se.instance_number = sb.instance_number (+)
           and se.stat_name       = 'background cpu time'
           and se.stat_name       = sb.stat_name  (+)
           and se.stat_id         = sb.stat_id (+)
      )
  )  s
  , (select 
  e.instance_number , sum((e.value - nvl(b.value,0)))  dbt
         from 
  dba_hist_sys_time_model b, dba_hist_sys_time_model e
      where e.dbid            = :dbid
        and e.dbid            = b.dbid (+)
        and e.instance_number IN (1,2,3,4)
        and e.instance_number = b.instance_number (+)
        and e.snap_id         = :eid
        and b.snap_id   (+)   = :bid
        and b.stat_id   (+)   = e.stat_id
        and e.stat_name = 'background elapsed time'
      group by e.instance_number
    ) tm
   where s.instance_number = tm.instance_number
   group by wc, nm, rollup(s.instance_number)
   )
 where rnk <= 100
 order by inststr, ttm desc, twt desc, nm;

prompt
prompt System Statistics - Per Second
REM SQL ID: 4zjfcunuu29fw Plan Hash: 3135803571

select st.instance_number AS INST
     , slr/s_et  slr_ps
     , phyr/s_et phyr_ps
     , phyw/s_et phyw_ps
     , rdos/1024/s_et rdos_ps
     , blkc/s_et blkc_ps
     , uc/s_et   uc_ps
     , ec/s_et   ec_ps
     , pc/s_et   pc_ps
     , lc/s_et   lc_ps
     , (ucom+urol)/s_et  tps
  from ((select se.instance_number
             , se.stat_name
             , (se.value - nvl(sb.value,0)) value
          from dba_hist_sysstat sb
              , dba_hist_sysstat se
         where se.dbid            = :dbid
           and sb.snap_id    (+)  = :bid
           and se.snap_id         = :eid
           and se.dbid            = sb.dbid            (+)
           and se.instance_number IN (1,2,3,4)
           and se.instance_number = sb.instance_number (+)
           and se.stat_id         = sb.stat_id         (+)
           and se.stat_name in
                 ( 'session logical reads', 'physical reads'
                 , 'physical writes' , 'db block changes'
                 , 'user calls', 'execute count'
                 , 'redo size', 'parse count (total)'
                 , 'logons cumulative'
                 , 'user commits','user rollbacks'
                 ))
       pivot (sum(value) for stat_name in (
                'session logical reads'     slr
               ,'physical reads'           phyr
               ,'physical writes'          phyw
               ,'redo size'                rdos
               ,'db block changes'         blkc
               ,'user calls'                 uc
               ,'execute count'              ec
               ,'parse count (total)'        pc
               ,'logons cumulative'          lc
               ,'user commits'             ucom
               ,'user rollbacks'           urol))) st
     , (select e.instance_number
              , extract(DAY     from e.end_interval_time
                                     -   b.end_interval_time) * 86400
                + extract(HOUR   from e.end_interval_time
                                     - b.end_interval_time) * 3600
                + extract(MINUTE from e.end_interval_time
                                     - b.end_interval_time) * 60
                + extract(SECOND from e.end_interval_time
                                     - b.end_interval_time)  s_et
          from dba_hist_snapshot e
             , dba_hist_snapshot b
          where e.dbid            = :dbid
            and b.snap_id         = :bid
            and e.snap_id         = :eid
            and e.dbid            = b.dbid
            and e.instance_number = b.instance_number
       ) s
 where st.instance_number = s.instance_number
 order by st.instance_number;

select 'Sum' AS INT
     , sum(slr_ps)  slr_ps
     , sum(phyr_ps) phyr_ps
     , sum(phyw_ps) phyw_ps
     , sum(rdos_ps) rdos_ps
     , sum(blkc_ps) blkc_ps
     , sum(uc_ps)   uc_ps
     , sum(ec_ps)   ec_ps
     , sum(pc_ps)   pc_ps
     , sum(lc_ps)   lc_ps
     , sum(tps)  tps
from
(select st.instance_number AS INST
     , slr/s_et  slr_ps
     , phyr/s_et phyr_ps
     , phyw/s_et phyw_ps
     , rdos/1024/s_et rdos_ps
     , blkc/s_et blkc_ps
     , uc/s_et   uc_ps
     , ec/s_et   ec_ps
     , pc/s_et   pc_ps
     , lc/s_et   lc_ps
     , (ucom+urol)/s_et  tps
     , s_et
  from ((select se.instance_number
             , se.stat_name
             , (se.value - nvl(sb.value,0)) value
          from dba_hist_sysstat sb
              , dba_hist_sysstat se
         where se.dbid            = :dbid
           and sb.snap_id    (+)  = :bid
           and se.snap_id         = :eid
           and se.dbid            = sb.dbid            (+)
           and se.instance_number IN (1,2,3,4)
           and se.instance_number = sb.instance_number (+)
           and se.stat_id         = sb.stat_id         (+)
           and se.stat_name in
                 ( 'session logical reads', 'physical reads'
                 , 'physical writes' , 'db block changes'
                 , 'user calls', 'execute count'
                 , 'redo size', 'parse count (total)'
                 , 'logons cumulative'
                 , 'user commits','user rollbacks'
                 ))
       pivot (sum(value) for stat_name in (
                'session logical reads'     slr
               ,'physical reads'           phyr
               ,'physical writes'          phyw
               ,'redo size'                rdos
               ,'db block changes'         blkc
               ,'user calls'                 uc
               ,'execute count'              ec
               ,'parse count (total)'        pc
               ,'logons cumulative'          lc
               ,'user commits'             ucom
               ,'user rollbacks'           urol))) st
     , (select e.instance_number
              , extract(DAY     from e.end_interval_time
                                     -   b.end_interval_time) * 86400
                + extract(HOUR   from e.end_interval_time
                                     - b.end_interval_time) * 3600
                + extract(MINUTE from e.end_interval_time
                                     - b.end_interval_time) * 60
                + extract(SECOND from e.end_interval_time
                                     - b.end_interval_time)  s_et
          from dba_hist_snapshot e
             , dba_hist_snapshot b
          where e.dbid            = :dbid
            and b.snap_id         = :bid
            and e.snap_id         = :eid
            and e.dbid            = b.dbid
            and e.instance_number = b.instance_number
       ) s
 where st.instance_number = s.instance_number
 order by st.instance_number);

col LC  format 990.99
col RC  format 990.99
col DSK  format 990.99

prompt
prompt Global Cache Efficiency Percentages
REM SQL ID: gtfyh8jn2cqr4 Plan Hash: 1788506064

select st.instance_number AS INST
     , (100*(1-(phyrc + gccrrv + gccurv)/(cgfc+dbfc)))   lc
     , (100*(gccurv+gccrrv)/(cgfc+dbfc))                 rc
     , (100*phyrc/(cgfc+dbfc))                           dsk
   from ((select se.instance_number, se.stat_name
              , (se.value - nvl(sb.value,0))          value
           from dba_hist_sysstat sb, dba_hist_sysstat se
          where se.dbid            = :dbid
            and sb.snap_id    (+)  = :bid
            and se.snap_id         = :eid
            and se.dbid            = sb.dbid            (+)
            and se.instance_number IN (1,2,3,4)
            and se.instance_number = sb.instance_number (+)
            and se.stat_id         = sb.stat_id         (+)
            and se.stat_name in
                ( 'gc cr blocks received', 'gc current blocks received'
                , 'physical reads cache'
                , 'consistent gets from cache', 'db block gets from cache'
                ))
              pivot (sum(value) for stat_name in (
                 'gc cr blocks received'          gccrrv
               , 'gc current blocks received'     gccurv
               , 'physical reads cache'            phyrc
               , 'consistent gets from cache'       cgfc
               , 'db block gets from cache'         dbfc))) st
  order by 
  instance_number;

prompt
prompt Ping Statistics
REM SQL ID: gbunadk6s7sd5 Plan Hash: 641778624

select e.instance_number AS INST
     , e.target_instance
     , e.cnt_500b-b.cnt_500b                cnt500b
     , (e.wait_500b-b.wait_500b)/1000000    wait500b
     , case when e.cnt_500b = b.cnt_500b then null
            else (e.wait_500b-b.wait_500b)/(e.cnt_500b-b.cnt_500b)/1000
       end av500b
     , case when e.cnt_500b = b.cnt_500b then null
            else           SQRT(ABS( ((1000*(e.waitsq_500b-b.waitsq_500b))/
                       greatest(e.cnt_500b-b.cnt_500b,1))
             - ( (e.wait_500b-b.wait_500b)/(e.cnt_500b-b.cnt_500b)
             * (e.wait_500b-b.wait_500b)/(e.cnt_500b-b.cnt_500b))))/1000
       end sd500b
     , e.cnt_8k-b.cnt_8k cnt8k
     , (e.wait_8k-b.wait_8k)/1000000 wait8k
     , case when e.cnt_8k = b.cnt_8k then null
            else (e.wait_8k-b.wait_8k)/(e.cnt_8k-b.cnt_8k)/1000
       end av8k
     , case when e.cnt_8k = b.cnt_8k then null
            else
              SQRT(ABS( ((1000*(e.waitsq_8k-b.waitsq_8k))/
                    greatest(e.cnt_8k-b.cnt_8k,1))
             - ( (e.wait_8k-b.wait_8k)/(e.cnt_8k-b.cnt_8k)
                * (e.wait_8k-b.wait_8k)/(e.cnt_8k-b.cnt_8k))))/1000
       end sd8k
  from dba_hist_interconnect_pings b , dba_hist_interconnect_pings e
 where b.snap_id         = :bid
   and e.snap_id         = :eid
   and e.dbid            = :dbid
   and e.instance_number IN (1,2,3,4)
   and b.instance_number = e.instance_number
   and b.dbid            = e.dbid
   and b.target_instance = e.target_instance
 order by e.instance_number, target_instance;


prompt
prompt Interconnect Client Statistics (per Second)
rem SQL ID: 599frthdgzjyu Plan Hash: 1796773463

select ic.instance_number AS INST
     , (cache_bs + ipq_bs + dlm_bs + ping_bs + diag_bs + cgs_bs + osm_bs
        + str_bs + int_bs + ksv_bs + ksxr_bs)/s_et/1048576 tot_bs_s
     , cache_bs/s_et/1048576                   cache_bs_s
     , ipq_bs/s_et/1048576                       ipq_bs_s
     , dlm_bs/s_et/1048576                       dlm_bs_s
     , ping_bs/s_et/1048576                     ping_bs_s
     , (diag_bs + cgs_bs + osm_bs + str_bs + int_bs + ksv_bs
        + ksxr_bs)/s_et/1048576 misc_bs_s
     , (cache_br + ipq_br + dlm_br + ping_br + diag_br + cgs_br + osm_br
       + str_br + int_br + ksv_br + ksxr_br)/s_et/1048576 tot_br_s
     , cache_br/s_et/1048576                   cache_br_s
     , ipq_br/s_et/1048576                       ipq_br_s
     , dlm_br/s_et/1048576                       dlm_br_s
     , ping_br/s_et/1048576                     ping_br_s
     , (diag_br + cgs_br + osm_br + str_br + int_br + ksv_br
       + ksxr_br)/s_et/1048576 misc_br_s
  from
   ((select e.instance_number
        , e.name
        , (e.bytes_sent     - b.bytes_sent)              bs
        , (e.bytes_received - b.bytes_received)          br
     from dba_hist_ic_client_stats b
        , dba_hist_ic_client_stats e
    where b.snap_id         = :bid
      and e.snap_id         = :eid
      and e.dbid            = :dbid
      and e.instance_number IN (1,2,3,4)
      and b.instance_number = e.instance_number
      and b.dbid            = e.dbid
      and b.name            = e.name)
    pivot (sum(bs) bs,sum(br)
  br for name in ('dlm' dlm
          ,'cache'    cache ,'ping'     ping ,'diag'     diag
          ,'cgs'      cgs ,'ksxr'     ksxr ,'ipq'      ipq
          ,'osmcache' osm ,'streams'  str ,'internal' int
          ,'ksv'      ksv)))   ic
    , (select e.instance_number
      , extract(DAY     from 
  e.end_interval_time - b.end_interval_time) * 86400      + extract(HOUR   
  from e.end_interval_time - b.end_interval_time) * 3600
        + extract(MINUTE from e.end_interval_time - b.end_interval_time) * 60
        + extract(SECOND from e.end_interval_time - b.end_interval_time)  s_et
         from dba_hist_snapshot e , dba_hist_snapshot b
        where e.dbid            = :dbid
          and b.snap_id         = :bid
          and e.snap_id         = :eid
          and e.dbid            = b.dbid
          and e.instance_number IN (1,2,3,4)
          and e.instance_number = b.instance_number) s
 where ic.instance_number = s.instance_number
 order by ic.instance_number;

select
'Sum' AS INT,
 sum(tot_bs_s) as tot_bs_s,
 sum(cache_bs_s) as cache_bs_s,
 sum(ipq_bs_s) as ipq_bs_s,
 sum(dlm_bs_s) as dlm_bs_s,
 sum(ping_bs_s) as ping_bs_s,
 sum(misc_bs_s) as misc_bs_s,
 sum(tot_br_s) as tot_br_s,
 sum(cache_br_s) as cache_br_s,
 sum(ipq_br_s) as ipq_br_s,
 sum(dlm_br_s) as dlm_br_s,
 sum(ping_br_s) as ping_br_s,
 sum(misc_br_s) as misc_br_s
from
(select ic.instance_number
     , (cache_bs + ipq_bs + dlm_bs + ping_bs + diag_bs + cgs_bs + osm_bs
        + str_bs + int_bs + ksv_bs + ksxr_bs)/s_et/1048576 tot_bs_s
     , cache_bs/s_et/1048576                   cache_bs_s
     , ipq_bs/s_et/1048576                       ipq_bs_s
     , dlm_bs/s_et/1048576                       dlm_bs_s
     , ping_bs/s_et/1048576                     ping_bs_s
     , (diag_bs + cgs_bs + osm_bs + str_bs + int_bs + ksv_bs
        + ksxr_bs)/s_et/1048576 misc_bs_s
     , (cache_br + ipq_br + dlm_br + ping_br + diag_br + cgs_br + osm_br
       + str_br + int_br + ksv_br + ksxr_br)/s_et/1048576 tot_br_s
     , cache_br/s_et/1048576                   cache_br_s
     , ipq_br/s_et/1048576                       ipq_br_s
     , dlm_br/s_et/1048576                       dlm_br_s
     , ping_br/s_et/1048576                     ping_br_s
     , (diag_br + cgs_br + osm_br + str_br + int_br + ksv_br
       + ksxr_br)/s_et/1048576 misc_br_s
  from
   ((select e.instance_number
        , e.name
        , (e.bytes_sent     - b.bytes_sent)              bs
        , (e.bytes_received - b.bytes_received)          br
     from dba_hist_ic_client_stats b
        , dba_hist_ic_client_stats e
    where b.snap_id         = :bid
      and e.snap_id         = :eid
      and e.dbid            = :dbid
      and e.instance_number IN (1,2,3,4)
      and b.instance_number = e.instance_number
      and b.dbid            = e.dbid
      and b.name            = e.name)
    pivot (sum(bs) bs,sum(br)
  br for name in ('dlm' dlm
          ,'cache'    cache ,'ping'     ping ,'diag'     diag
          ,'cgs'      cgs ,'ksxr'     ksxr ,'ipq'      ipq
          ,'osmcache' osm ,'streams'  str ,'internal' int
          ,'ksv'      ksv)))   ic
    , (select e.instance_number
      , extract(DAY     from 
  e.end_interval_time - b.end_interval_time) * 86400      + extract(HOUR   
  from e.end_interval_time - b.end_interval_time) * 3600
        + extract(MINUTE from e.end_interval_time - b.end_interval_time) * 60
        + extract(SECOND from e.end_interval_time - b.end_interval_time)  s_et
         from dba_hist_snapshot e , dba_hist_snapshot b
        where e.dbid            = :dbid
          and b.snap_id         = :bid
          and e.snap_id         = :eid
          and e.dbid            = b.dbid
          and e.instance_number IN (1,2,3,4)
          and e.instance_number = b.instance_number) s
 where ic.instance_number = s.instance_number
 order by ic.instance_number);


exit
