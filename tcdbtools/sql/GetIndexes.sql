SELECT 
    OBJECT_SCHEMA_NAME(i.[object_id]) AS [schema_name],
    OBJECT_NAME(i.[object_id]) AS [object_name],
    i.[index_id],
    i.[name] AS [index_name],
    i.[type_desc] AS [index_type]
FROM [{0}].[sys].[indexes] i
INNER JOIN [{0}].[sys].[filegroups] f
    ON f.[data_space_id] = i.[data_space_id]
WHERE OBJECTPROPERTY(i.[object_id], 'IsUserTable') = 1
    AND [f].[name] = '{1}'--<<extra_where>>
ORDER BY OBJECT_NAME(i.[object_id]),
    i.[index_id]