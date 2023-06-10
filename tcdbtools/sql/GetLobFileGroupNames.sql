SELECT OBJECT_SCHEMA_NAME([t].[object_id]) AS [schema_name],
	[t].[name] AS [table_name],
	[ds].[name] AS [filegroup_name]
FROM sys.[tables] AS [t] 
INNER JOIN sys.[data_spaces] AS [ds] 
	ON [ds].[data_space_id]  = [t].[lob_data_space_id]
