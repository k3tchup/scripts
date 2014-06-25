SELECT t.schema_name+ ‘ – ‘+ t.table_name as schema_table
, t.index_name
, sum(t.used) as used_in_kb
, sum(t.reserved) as reserved_in_kb
, sum(t.tbl_rows) as rows
from
(
SELECT s.Name schema_name
, o.Name table_name
, coalesce(i.Name, ‘HEAP’) index_name
, p.used_page_count * 8 used
, p.reserved_page_count * 8 reserved
, p.row_count ind_rows
, case when i.index_id in ( 0, 1 ) then p.row_count else 0 end tbl_rows
FROM sys.dm_db_partition_stats p
INNER JOIN sys.objects as o
ON o.object_id = p.object_id
INNER JOIN sys.schemas as s
ON s.schema_id = o.schema_id
LEFT OUTER JOIN sys.indexes as i
on i.object_id = p.object_id and i.index_id = p.index_id
WHERE o.type_desc = ‘USER_TABLE’
and o.is_ms_shipped = 0
) as t
GROUP BY
t.schema_name, t.table_name
, t.index_name
ORDER BY
5 desc