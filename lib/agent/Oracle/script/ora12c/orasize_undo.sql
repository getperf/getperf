select * from (
select 'UNDO DEFINE SIZE' NAME,tablespace_name ,sum(bytes)/1024/1024 "BYTES(MB)" from dba_data_files
where tablespace_name like 'UNDO%'
group by tablespace_name
)
union
(
select 'UNDO ALLOCATION SIZE' NAME,TABLESPACE_NAME,sum(bytes)/1024/1024 "BYTES(MB)" from dba_extents
where TABLESPACE_NAME like 'UNDO%'
group by TABLESPACE_NAME)
union
(
select status,TABLESPACE_NAME, sum(bytes)/1024/1024 "BYTES(MB)" from dba_undo_extents
where tablespace_name like 'UNDO%'
group by status,TABLESPACE_NAME)
;
