

SELECT 
	DB_NAME() as [db_name],
	fn.[table_name],
	c.[Name] AS [column_name], 
	fn2.[type_name_desc]
FROM sys.[columns] c
INNER JOIN sys.[columns] c2 
	ON [c].[name] = [c2].[name]
	AND c.[object_id] <> c2.[object_id]
CROSS APPLY (
	SELECT CONCAT(OBJECT_SCHEMA_NAME(c.[object_id]), '.', OBJECT_NAME(c.[object_id])) AS [table_name],
		UPPER(TYPE_NAME(c.[system_type_id])) AS [type_name]
) fn
CROSS APPLY (
	SELECT 
		CASE 
			WHEN fn.[type_name] IN ('varchar','char','nvarchar','nchar','varbinary') THEN CONCAT(fn.[type_name], ' (', CASE WHEN c.[max_length] = -1 THEN 'MAX' ELSE CAST(c.[max_length] AS varchar(20)) END, ')')
			WHEN fn.[type_name] IN ('datetime2','datetimeoffset','time') THEN CONCAT(fn.[type_name], ' (', c.[scale], ')')
			WHEN fn.[type_name] IN ('decimal') THEN CONCAT(fn.[type_name], ' (', c.[precision], ',', c.[scale], ')')
			WHEN fn.[type_name] IN ('float') THEN CONCAT(fn.[type_name], ' (', c.[precision], ')')
			ELSE fn.[type_name]
		END AS [type_name_desc]
) fn2
WHERE OBJECTPROPERTY(c.[object_id], 'IsMsShipped') = 0
	AND OBJECTPROPERTY(c2.[object_id], 'IsMsShipped') = 0
	AND (
		c.[system_type_id] <> c2.[system_type_id] 
		OR c.[max_length] <> c2.[max_length]
		OR c.[precision] <> c2.[precision]
		OR c.[scale] <> c2.[scale]
	)
GROUP BY c.[name], 
	fn.[table_name],
	fn2.[type_name_desc]
ORDER BY c.[name], 
	fn.[table_name],
	fn2.[type_name_desc]

