# Graph Template : Load
cacti-cli -f -g lib/graph/Oracle/ora_system_stat_rac.json
cacti-cli -f -g lib/graph/Oracle/ora_cache_hit_rac.json

# Greph Template : Event
cacti-cli -f -g lib/graph/Oracle/ora_time_model_rac.json
cacti-cli -f -g lib/graph/Oracle/ora_foreground_wait_rac.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Application.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Cluster.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Commit.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Concurrency.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Configuration.json
cacti-cli -f -g lib/graph/Oracle/ora_event_NA.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Network.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Other.json
cacti-cli -f -g lib/graph/Oracle/ora_event_Scheduler.json
cacti-cli -f -g lib/graph/Oracle/ora_event_SystemIO.json
cacti-cli -f -g lib/graph/Oracle/ora_event_UserIO.json

cacti-cli -f -g lib/graph/Oracle/ora_background_event_Application.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_Cluster.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_Commit.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_Concurrency.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_Configuration.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_NA.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_Network.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_Other.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_Scheduler.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_SystemIO.json
cacti-cli -f -g lib/graph/Oracle/ora_background_event_UserIO.json

# Greph Template : Session
# cacti-cli -f -g lib/graph/Oracle/ora_ses.json
cacti-cli -f -g lib/graph/Oracle/ora_sesg.json

# Greph Template : Storage
cacti-cli -f -g lib/graph/Oracle/ora_asm.json
cacti-cli -f -g lib/graph/Oracle/ora_seg_table.json
cacti-cli -f -g lib/graph/Oracle/ora_seg_index.json
cacti-cli -f -g lib/graph/Oracle/ora_seg_etc.json
cacti-cli -f -g lib/graph/Oracle/ora_tbs.json

# Greph Template : Net
cacti-cli -f -g lib/graph/Oracle/ora_interconnect_rac.json
cacti-cli -f -g lib/graph/Oracle/ora_ping_rac.json

# Greph Template : SQL, Object Ranking
#cacti-cli -f -g lib/graph/Oracle/ora_sql_top_by_buffer_gets.json
#cacti-cli -f -g lib/graph/Oracle/ora_sql_top_by_cpu_time.json
#cacti-cli -f -g lib/graph/Oracle/ora_sql_top_by_disk_reads.json
#cacti-cli -f -g lib/graph/Oracle/ora_obj_top_by_buffer_gets.json
#cacti-cli -f -g lib/graph/Oracle/ora_obj_top_by_disk_reads.json
#cacti-cli -f -g lib/graph/Oracle/ora_obj_top_by_logical_reads.json
#cacti-cli -f -g lib/graph/Oracle/ora_obj_top_by_physical_reads.json
#cacti-cli -f -g lib/graph/Oracle/ora_obj_top_by_physical_writes.json

# Graph creation

cacti-cli -f node/Oracle/EESDBM12  --device-sort natural
cacti-cli -f node/Oracle/EESDBM12_instance1  --device-sort natural
cacti-cli -f node/Oracle/EESDBM12_instance2  --device-sort natural
cacti-cli -f node/Oracle/EESDBM12_instance3  --device-sort natural
cacti-cli -f node/Oracle/EESDBM12_instance4  --device-sort natural


