-- more info: https://sqlity.net/en/2344/create-login-with-hashed-password/
-- DECLARE @gen_auto_fix BIT = 1,	/* IF 1 then the script to autofix the login in all the databases will be output */
-- 	@drop_if_exists BIT = 0		/* IF 1 then the login will be dropped if exists, else it will only be dropped if the login and sid do not match */

DECLARE @tab VARCHAR(1) = CASE WHEN @drop_if_exists = 1 THEN CHAR(9) ELSE '' END,
	@crlf CHAR(2) = CONCAT(CHAR(13), CHAR(10))

SELECT [sp].[name], [sp].[create_date], [sp].[modify_date], [sp].[is_disabled], [sp].[type_desc], [fn].[login_sid], [fn].[pwd_hash], @@SERVERNAME AS [server_name], [create_or_alter_sql] = 
@tab + '/*' + REPLICATE('*', 30) + REPLICATE('*', LEN(fn.generated_context) + 1) + REPLICATE('*', 30)  + '*/' + @crlf +
@tab + '/*' + REPLICATE('*', 30) + fn.generated_context + REPLICATE('*', 30)  + '*/' + @crlf +
@tab + '/*' + REPLICATE('*', 30) + REPLICATE('*', LEN(fn.generated_context) + 1) + REPLICATE('*', 30)  + '*/' + @crlf +
@tab + 'SET @checked = (SELECT [is_policy_checked] FROM sys.sql_logins WHERE name = ''' + sp.name + ''')' + @crlf +
@tab + 'IF @checked = 1 BEGIN ALTER LOGIN [' + sp.name + '] WITH CHECK_POLICY = OFF END' + @crlf +
CASE WHEN @drop_if_exists = 1 
	THEN '' 
	ELSE 'IF NOT EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = ''' + sp.name + ''' AND sp.sid = ' + fn.login_sid + ') BEGIN' 
END + '	
	RAISERROR(''********************************[' + sp.name + ']********************************'', 0, 1) WITH NOWAIT;
	IF EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = ''' + sp.name + ''') BEGIN;
		RAISERROR(''DROPPING LOGIN [' + sp.name + ']'', 0, 1) WITH NOWAIT;
		DROP LOGIN [' + sp.name + '];
	END;
	RAISERROR(''CREATING LOGIN [' + sp.name + ']'', 0, 1) WITH NOWAIT;
	CREATE LOGIN [' + sp.name + ']  
			WITH PASSWORD = ' + fn.pwd_hash + ' HASHED, 
			DEFAULT_DATABASE = [' + sp.default_database_name + '], 
			DEFAULT_LANGUAGE = [' + sp.default_language_name + '], 
			SID = ' + fn.login_sid + ';' + 
CASE WHEN @drop_if_exists = 1 
	THEN '' 
	ELSE '
END ELSE BEGIN
	RAISERROR(''ALTERING LOGIN [' + sp.name + ']'', 0, 1) WITH NOWAIT;
	ALTER LOGIN [' + sp.name + ']  
		WITH PASSWORD = ' + fn.pwd_hash + ' HASHED, 
		DEFAULT_DATABASE = [' + sp.default_database_name + '], 
		DEFAULT_LANGUAGE = [' + sp.default_language_name + '];
END' + 
CASE WHEN @gen_auto_fix = 0 or sp.name IN ('sa', 'dbo') THEN '' ELSE '

RAISERROR(''AUTO FIXING LOGIN [' + sp.name + ']'', 0, 1) WITH NOWAIT;
EXEC sys.sp_MSForeachdb N''
	USE [?]; 
	IF EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = ''''?'''' AND d.is_read_only = 0) BEGIN
		IF EXISTS (SELECT 1 FROM sys.database_principals dp WHERE dp.name = ''''' + sp.name + ''''') BEGIN
			EXEC sys.sp_change_users_login @Action = ''''Update_One'''', @UserNamePattern = ''''' + sp.name + ''''', @LoginName = ''''' + sp.name + '''''
		END 
	END
''' END  
END + @crlf + @crlf + @tab + 'IF @checked = 1 BEGIN ALTER LOGIN [' + sp.name + '] WITH CHECK_POLICY = ON END' + 
@tab + CASE WHEN [sp].[is_disabled] = 1 THEN @crlf + 'ALTER LOGIN [' + sp.name + '] DISABLE' ELSE '' END + ';' + @crlf + @crlf
FROM sys.server_principals sp 
CROSS APPLY (
	SELECT login_sid = CONVERT(NVARCHAR(4000), sp.sid, 1),
		pwd_hash = CONVERT(NVARCHAR(4000), LOGINPROPERTY(sp.name,'PASSWORDHASH'), 1),
        generated_context = CONCAT(' Login: ', sp.name, ' generated from: ', @@SERVERNAME, ' on: ', CONVERT(VARCHAR, GETDATE(), 120), ' ')
) fn
WHERE [sp].[type_desc] = 'SQL_LOGIN' COLLATE SQL_Latin1_General_CP1_CI_AS
	AND [sp].[name] NOT LIKE 'NT Service%' COLLATE SQL_Latin1_General_CP1_CI_AS
    AND [sp].[name] NOT LIKE 'NT AUTHORITY%' COLLATE SQL_Latin1_General_CP1_CI_AS
    AND [sp].[name] NOT LIKE '##%'
	AND [sp].[name] COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN ('dbo', 'sa') 
ORDER BY [sp].[name]