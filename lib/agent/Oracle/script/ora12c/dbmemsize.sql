SELECT
    component name,
    CURRENT_SIZE / 1024 / 1024 AS CURRENT_SIZE
FROM
    V$sga_dynamic_components
WHERE
    component IN('shared pool', 'large pool', 'java pool', 'streams pool', 'DEFAULT buffer cache', 'KEEP buffer cache')
UNION
SELECT
    name,
    value / 1024 / 1024 AS CURRENT_SIZE
FROM
    v$parameter
WHERE
    name IN('sga_max_size')
UNION
SELECT
    'keep_use_size',
    SUM(bytes / 1024 / 1024) AS BYTES
FROM
    dba_segments
WHERE
    buffer_pool = 'KEEP'
;
