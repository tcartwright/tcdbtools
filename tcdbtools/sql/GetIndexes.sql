SELECT
	OBJECT_SCHEMA_NAME(p.[object_id]) AS [schema_name],
    OBJECT_NAME(p.[object_id]) AS [object_name],
	p.[index_id],
    i.[name] AS [index_name],
    i.[type_desc] AS [index_type],
    au.type_desc AS [alloc_unit_type],
    fg.name AS fg_name
FROM [{0}].sys.partitions as p
INNER JOIN [{0}].sys.allocation_units AS au 
	ON p.hobt_id = au.container_id
INNER JOIN [{0}].sys.filegroups AS fg 
	ON fg.data_space_id = au.data_space_id
INNER JOIN [{0}].sys.[indexes] AS [i] 
	ON [i].[object_id] = [p].[object_id] 
	AND [i].[index_id] = [p].[index_id]
WHERE OBJECTPROPERTY(p.[object_id], 'IsUserTable') = 1
    AND [fg].[name] = '{1}'--<<extra_where>>
ORDER BY
   [schema_name], [object_name], p.index_id, alloc_unit_type