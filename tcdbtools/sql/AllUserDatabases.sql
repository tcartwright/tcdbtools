SELECT d.[name]
FROM sys.databases d 
WHERE [d].[database_id] > 4 
	AND HAS_DBACCESS(d.[name]) = 1 
	AND [d].[state] = 0
	AND [d].[is_read_only] = 0
ORDER BY [d].[name]