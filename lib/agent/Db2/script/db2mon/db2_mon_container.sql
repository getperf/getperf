SELECT CURRENT TIMESTAMP AS TIMESTAMP,T.* FROM TABLE(MON_GET_CONTAINER('', -1)) AS T;
