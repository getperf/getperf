SELECT owner  username,segment_type  segment_type,SUM(bytes)/1048576  mbytes,
       tablespace_name  tablespace_name
FROM dba_segments
GROUP BY owner, tablespace_name,segment_type
ORDER BY owner, segment_type,tablespace_name
;
