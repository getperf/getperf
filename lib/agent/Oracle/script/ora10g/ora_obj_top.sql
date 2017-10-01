select time
     , n.owner
     , decode(n.subobject_name,NULL,n.object_name,n.object_name||'('||n.subobject_name||')') OBJECT_NAME
     , n.object_type
     , x.BUFFER_POOL
     , sum(x.bytes)
     , sum(r.logical_reads)
     , sum(r.physical_reads)
  from stats$seg_stat_obj n
     , (select *
          from (select to_char ( i.snap_time, 'YYYY/MM/DD HH24:MI:SS' ) time 
                     , e.dataobj#
                     , e.obj#
                     , e.dbid
                     , e.logical_reads - nvl(b.logical_reads, 0) logical_reads
                     , e.physical_reads - nvl(b.physical_reads, 0) physical_reads
                  from stats$seg_stat e
                     , stats$seg_stat b
                     , stats$snapshot i
                 where b.snap_id                                  = &STARTSNAP_ID
                   and e.snap_id                                  = &ENDSNAP_ID
                   and i.snap_id                                  = e.snap_id
                   and b.dbid                                     = e.dbid
                   and b.instance_number                          = e.instance_number
                   and e.obj#                                     = b.obj#
                   and e.dataobj#                                 = b.dataobj#
                   and e.logical_reads - nvl(b.logical_reads, 0)  > 0
                 order by logical_reads desc) d
          where rownum <= 101
union
        select *
          from (select to_char ( i.snap_time, 'YYYY/MM/DD HH24:MI:SS' ) time 
                     , e.dataobj#
                     , e.obj#
                     , e.dbid
                     , e.logical_reads - nvl(b.logical_reads, 0) logical_reads
                     , e.physical_reads - nvl(b.physical_reads, 0) physical_reads
                  from stats$seg_stat e
                     , stats$seg_stat b
                     , stats$snapshot i
                 where b.snap_id                                  = &STARTSNAP_ID
                   and e.snap_id                                  = &ENDSNAP_ID
                   and i.snap_id                                  = e.snap_id
                   and b.dbid                                     = e.dbid
                   and b.instance_number                          = e.instance_number
                   and e.obj#                                     = b.obj#
                   and e.dataobj#                                 = b.dataobj#
                   and e.physical_reads - nvl(b.physical_reads, 0)  > 0
                 order by physical_reads desc) d
          where rownum <= 101
) r,dba_segments x
 where n.dataobj# = r.dataobj#
   and n.obj#     = r.obj#
   and n.dbid     = r.dbid
   and n.object_name = x.segment_name
   and n.owner = x.owner
   and n.object_type = x.segment_type
   and NVL(n.SUBOBJECT_NAME,'0') = NVL(x.PARTITION_NAME,'0')
group by 
     time
     , n.owner
     , decode(n.subobject_name,NULL,n.object_name,n.object_name||'('||n.subobject_name||')') 
     , n.object_type
     , x.BUFFER_POOL
;
