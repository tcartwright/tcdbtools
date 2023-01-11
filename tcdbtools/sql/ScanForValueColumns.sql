DECLARE @crlf CHAR(2) = CHAR(13) + CHAR(10)

SELECT OBJECT_SCHEMA_NAME(t.object_id) AS [schema_name], t.name AS [table_name], c.name AS [column_name], 
	[query] = N'SELECT DB_NAME() AS [db_name], ''' + OBJECT_SCHEMA_NAME(t.object_id)  + 
	''' AS [schema_name], ''' + t.name + ''' AS [table_name], ''' + c.name + 
	''' AS [column_name], CAST([' + c.name + '] AS VARCHAR(MAX)) AS [value]' + @crlf + 
	'FROM [' + OBJECT_SCHEMA_NAME(t.object_id) + '].[' + t.name + ']' + @crlf + 
	'WHERE [' + c.name + '] LIKE @lookfor' + @crlf + 
	'UNION ALL'
FROM sys.tables t 
INNER JOIN sys.columns c ON c.object_id = t.object_id
INNER JOIN sys.types typ ON typ.system_type_id = c.system_type_id
WHERE t.is_ms_shipped = 0 
	AND c.is_identity = 0 
	AND c.is_computed = 0
	AND c.is_filestream = 0
	AND CASE 
		WHEN @lookForType = 'number' AND typ.name IN ('tinyint','smallint','int','real','money','float','sql_variant','decimal','numeric','smallmoney','bigint') THEN 1
		WHEN @lookForType = 'string' AND typ.name IN ('sql_variant','varchar','char','nvarchar','nchar','sysname') THEN 1
		ELSE 0
	END = 1
	AND (@includeMaxLengthColumns = 1 OR c.max_length <> -1)<<extra_where>>
ORDER BY OBJECT_SCHEMA_NAME(t.object_id), t.name