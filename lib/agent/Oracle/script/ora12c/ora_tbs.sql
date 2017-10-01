select a.TABLESPACE_NAME,
	min(a.BYTES)/1024/1024 "total_mb",
	round(min(a.BYTES)/(1024*1024) - sum(b.BYTES)/ (1024*1024),2) "used_mb",
    round((min(a.BYTES)/(1024*1024) - sum(b.BYTES)/(1024*1024))/ (min(a.BYTES)/1024/1024)*100,2) "usage",
    round(sum(b.BYTES)/(1024*1024),2) "available_mb"
from dba_data_files a, dba_free_space b
where a.FILE_ID = b.FILE_ID
group by a.TABLESPACE_NAME
;
