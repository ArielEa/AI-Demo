SELECT
    p.segment_name AS partition_name,
    p.segment_type,
    p.owner AS table_owner,
    p.tablespace_name,
    ROUND(SUM(p.bytes)/1024/1024, 2) AS partition_size_mb,
    ROUND(MAX(t.total_bytes)/1024/1024, 2) AS tbs_total_mb,
    ROUND(MAX(t.total_bytes - NVL(f.free_bytes,0))/1024/1024, 2) AS tbs_used_mb,
    ROUND(MAX(NVL(f.free_bytes,0))/1024/1024, 2) AS tbs_free_mb,
    ROUND(MAX((t.total_bytes - NVL(f.free_bytes,0))/t.total_bytes*100), 2) AS tbs_used_rate
FROM
    dba_segments p
    JOIN (
        SELECT tablespace_name, SUM(bytes) AS total_bytes
        FROM dba_data_files
        GROUP BY tablespace_name
    ) t
    ON p.tablespace_name = t.tablespace_name
    LEFT JOIN (
        SELECT tablespace_name AS free_tbs_name, SUM(bytes) AS free_bytes
        FROM dba_free_space
        GROUP BY tablespace_name
    ) f
    ON p.tablespace_name = f.free_tbs_name
WHERE
    p.segment_type LIKE 'TABLE PARTITION%'
GROUP BY
    p.segment_name,
    p.segment_type,
    p.owner,
    p.tablespace_name
ORDER BY
    p.segment_name;
