-- remove any lingering pf functions or schemes as they will block the FG from being removed... 
DECLARE @sql VARCHAR(MAX) = '',
	@crlf CHAR(2) = CHAR(13) + CHAR(10)

SELECT @sql += CONCAT('DROP PARTITION SCHEME [', [ps].[name], '];', @crlf) 
FROM sys.partition_schemes ps 
WHERE [ps].[name] LIKE 'PS_MOVE_HELPER_%'

SELECT @sql += CONCAT('DROP PARTITION FUNCTION [', [pf].[name], '];', @crlf) 
FROM sys.[partition_functions] AS [pf] 
WHERE [pf].[name] LIKE 'PF_MOVE_HELPER_%'

PRINT @sql
EXEC (@sql) 

IF EXISTS (SELECT 1 FROM [{0}].sys.[database_files] AS [df] WHERE [df].[name] = 'SHRINK_DATA_TEMP') BEGIN
    ALTER DATABASE [{0}] REMOVE FILE [SHRINK_DATA_TEMP]
END

IF EXISTS (SELECT 1 FROM [{0}].sys.[filegroups] AS [f] WHERE [f].[name] = 'SHRINK_DATA_TEMP') BEGIN
    ALTER DATABASE [{0}] REMOVE FILEGROUP [SHRINK_DATA_TEMP]
END