SELECT CURRENT TIMESTAMP AS TIMESTAMP,T.* FROM TABLE(MON_GET_APPL_LOCKWAIT(NULL, -1)) AS T;
