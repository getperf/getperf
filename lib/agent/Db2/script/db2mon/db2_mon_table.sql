SELECT CURRENT TIMESTAMP AS TIMESTAMP,T.* FROM TABLE(MON_GET_TABLE('', '', -2)) AS T;
