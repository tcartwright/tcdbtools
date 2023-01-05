SET NOCOUNT ON
DECLARE @desired_collation sysname = 'SQL_Latin1_General_CP1_CI_AS'

/****************************************************************************************************/
SELECT 'SERVER OPTIONS' AS [container] 
/****************************************************************************************************/

/*
    Author: Tim Cartwright
    Purpose: Allows you to check the server, and client SET options

    https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-user-options-server-configuration-option
    1        DISABLE_DEF_CNST_CHK     Controls interim or deferred constraint checking.
    2        IMPLICIT_TRANSACTIONS    For dblib network library connections, controls whether a transaction is started implicitly when a statement is executed. The IMPLICIT_TRANSACTIONS setting has no effect on ODBC or OLEDB connections.
    4        CURSOR_CLOSE_ON_COMMIT   Controls behavior of cursors after a commit operation has been performed.
    8        ANSI_WARNINGS            Controls truncation and NULL in aggregate warnings.
    16       ANSI_PADDING             Controls padding of fixed-length variables.
    32       ANSI_NULLS               Controls NULL handling when using equality operators.
    64       ARITHABORT               Terminates a query when an overflow or divide-by-zero error occurs during query execution.
    128      ARITHIGNORE              Returns NULL when an overflow or divide-by-zero error occurs during a query.
    256      QUOTED_IDENTIFIER        Differentiates between single and double quotation marks when evaluating an expression.
    512      NOCOUNT                  Turns off the message returned at the end of each statement that states how many rows were affected.
    1024     ANSI_NULL_DFLT_ON        Alters the session's behavior to use ANSI compatibility for nullability. New columns defined without explicit nullability are defined to allow nulls.
    2048     ANSI_NULL_DFLT_OFF       Alters the session's behavior not to use ANSI compatibility for nullability. New columns defined without explicit nullability do not allow nulls.
    4096     CONCAT_NULL_YIELDS_NULL  Returns NULL when concatenating a NULL value with a string.
    8192     NUMERIC_ROUNDABORT       Generates an error when a loss of precision occurs in an expression.
    16384    XACT_ABORT               Rolls back a transaction if a Transact-SQL statement raises a run-time error.
*/

DECLARE @options TABLE ([name] nvarchar(35), [minimum] int, [maximum] int, [config_value] int, [run_value] int)
DECLARE @optionsCheck TABLE(
    [id] int NOT NULL IDENTITY, 
    [setting_name] varchar(128),
    [setting_value] AS (CASE WHEN id > 1 THEN POWER(2, id - 1) ELSE 1 END) PERSISTED
)
DECLARE @current_value INT;

INSERT INTO @options ([name], [minimum], [maximum], [config_value], [run_value])
EXEC sys.sp_configure 'user_options';

SELECT @current_value = [config_value] FROM @options;

INSERT INTO @optionsCheck 
    ([setting_name]) 
VALUES
    ('DISABLE_DEF_CNST_CHK'),
    ('IMPLICIT_TRANSACTIONS'),
    ('CURSOR_CLOSE_ON_COMMIT'),
    ('ANSI_WARNINGS'),
    ('ANSI_PADDING'),
    ('ANSI_NULLS'),
    ('ARITHABORT'),
    ('ARITHIGNORE'),
    ('QUOTED_IDENTIFIER'),
    ('NOCOUNT'),
    ('ANSI_NULL_DFLT_ON'),
    ('ANSI_NULL_DFLT_OFF'),
    ('CONCAT_NULL_YIELDS_NULL'),
    ('NUMERIC_ROUNDABORT'),
    ('XACT_ABORT')

SELECT 
    [oc].[setting_name],   
    [setting_value] = CASE WHEN fn.[is_on] = 1 THEN 'X' ELSE '' END
FROM @optionsCheck oc
CROSS APPLY (
    SELECT [is_on] = CASE 
        WHEN (@current_value & oc.[setting_value]) = oc.[setting_value] THEN 1 
        ELSE 0 
    END
) fn
--WHERE [fn].[is_on] = 1

/****************************************************************************************************/
SELECT 'SERVER SETTINGS' AS [container] 
/****************************************************************************************************/
-- server options
SELECT 
    [affinity_mask] = MAX(t.affinity_mask),
    [affinity_IO_mask] = MAX(t.affinity_IO_mask),
    [affinity64_mask] = MAX(t.affinity64_mask),
    [affinity64_IO_mask] = MAX(t.affinity64_IO_mask),
    [cost_of_parallelism] = MAX(t.cop),
    [cross_db_owner_chaining] = MAX(t.cross_db_owner_chaining),
    [default_trace] = MAX(t.default_trace),
    [disallow_results_from_triggers] = MAX([t].[disallow_results_from_triggers]),
    [fill_factor] = MAX(t.global_fill_factor),
    [locks] = MAX(t.locks),
    [max_dop] = MAX(t.max_dop),
    [max_server_memory_MB] = MAX(t.max_server_memory_MB),
    [ole_automation] = MAX(t.ole_automation),
    [user_connections] = MAX(t.[user_connections]),
    [user_options] = MAX(t.user_options),
    [xp_cmdshell] = MAX(t.xp_cmdshell)
FROM (
    SELECT     
        CASE WHEN c.name = 'fill factor (%)' AND c.value > 0 THEN 'X' ELSE '' END AS [global_fill_factor],
        CASE WHEN c.name = 'cross db ownership chaining' AND c.value = 1 THEN 'X' ELSE '' END AS [cross_db_owner_chaining],
        CASE WHEN c.name = 'user options' AND c.value <> 0 THEN 'X' ELSE '' END AS [user_options],
        CASE WHEN c.name = 'max degree of parallelism' AND (c.value < 2 OR c.[value] > 32) THEN 'X' ELSE '' END AS [max_dop],
        CASE WHEN c.name = 'cost threshold for parallelism' AND (c.value <= 20 OR c.[value] > 100) THEN 'X' ELSE '' END AS [cop],
        CASE WHEN c.name = 'default trace enabled' AND c.value = 0 THEN 'X' ELSE '' END AS [default_trace],
        CASE WHEN c.name = 'Ole Automation Procedures' AND c.value = 1 THEN 'X' ELSE '' END AS [ole_automation],
        CASE WHEN c.name = 'xp_cmdshell' AND c.value = 1 THEN 'X' ELSE '' END AS [xp_cmdshell],
        CASE WHEN c.name = 'affinity mask' AND c.value <> 0 THEN 'X' ELSE '' END AS [affinity_mask],
        CASE WHEN c.name = 'affinity64 mask' AND c.value <> 0 THEN 'X' ELSE '' END AS [affinity64_mask],
        CASE WHEN c.name = 'affinity I/O mask' AND c.value <> 0  THEN 'X' ELSE '' END AS [affinity_IO_mask],
        CASE WHEN c.name = 'affinity64 I/O mask' AND c.value <> 0 THEN 'X' ELSE '' END AS [affinity64_IO_mask],
        CASE WHEN c.name = 'max server memory (MB)' AND c.value <= 2000 THEN 'X' ELSE '' END AS [max_server_memory_MB],
        CASE WHEN c.name = 'user connections' AND c.value <> 0 THEN 'X' ELSE '' END AS [user_connections],
        CASE WHEN c.name = 'locks' AND c.value <> 0 THEN 'X' ELSE '' END AS [locks],
        CASE WHEN c.name = 'disallow results from triggers' AND c.value <> 0 THEN 'X' ELSE '' END AS [disallow_results_from_triggers]
    FROM sys.configurations c
) t

-- SELECT * FROM sys.configurations c ORDER BY c.name

/****************************************************************************************************/
SELECT 'DATABASE FILE GROWTHS' AS [container] 
/****************************************************************************************************/

IF OBJECT_ID('tempdb..#file_growths') IS NOT NULL BEGIN 
    DROP TABLE #file_growths 
END

CREATE TABLE #file_growths (
    [db_name] sysname,
    [file_name] sysname,
    growth_kb DECIMAL(18,2),
    growth_mb DECIMAL(18,2),
    is_percent_growth BIT
)

INSERT INTO [#file_growths] (
    [db_name],
    [file_name],
    [growth_kb],
    [growth_mb],
    [is_percent_growth]
)
EXEC sys.sp_MSforeachdb N' 
    USE [?]; 
    IF DB_ID() <= 4 RETURN
    SELECT [db_name] = DB_NAME(), 
        [file_name] = df.name,
        fn.growth_kb, 
        fn.growth_mb, 
        df.is_percent_growth
    FROM sys.database_files df
    CROSS APPLY (
        SELECT [growth_kb] = df.growth * 8.0,
            [growth_mb] = df.growth / 128.0
    ) fn
    WHERE df.is_percent_growth = 1
        OR (
            df.growth > 0
            AND (
                fn.growth_mb < 64 OR fn.growth_mb > 2000
            )
        )'

-- find databases that have abnormal file growths. 
SELECT 
    [fg].[db_name] AS [database_name],
    [fg].[file_name],
    [fg].[growth_kb],
    [fg].[growth_mb],
    [fg].[is_percent_growth] 
FROM #file_growths fg 
ORDER BY fg.db_name, 
    fg.file_name

/****************************************************************************************************/
SELECT 'DATABASE' AS [container] 
/****************************************************************************************************/
-- find databases with possible bad options
SELECT name AS [database_name], 
    -- owner is not SA
    CASE WHEN d.owner_sid <> 0x01 THEN 'X' ELSE '' END AS [owner_is_sa],
    /* change the collation to your desired collation */
    CASE WHEN d.collation_name <> @desired_collation THEN 'X' ELSE '' END AS [collation_name], /*this varies from region to region*/
    /* dbs should never have auto close on */
    CASE WHEN d.is_auto_close_on = 1 THEN 'X' ELSE '' END AS [is_auto_close_on], 
    /* this should be turned on */
    CASE WHEN d.page_verify_option_desc <> 'CHECKSUM' THEN 'X' ELSE '' END AS [page_verify_option], 
    /* there can be valid reasons for this, but it should be justified */
    CASE WHEN d.is_auto_create_stats_on = 0 THEN 'X' ELSE '' END AS [is_auto_create_stats_on], 
    /* this should be on, so any object created without setting this setting will have it on by default */
    CASE WHEN d.is_quoted_identifier_on = 0 THEN 'X' ELSE '' END AS [is_quoted_identifier_on],
    /* this can cause issues if on with certain types of queries */
    CASE WHEN d.is_numeric_roundabort_on = 1 THEN 'X' ELSE '' END AS [is_numeric_roundabort_on], 
    /* recursive triggers are a design nightmare and should be avoided */
    CASE WHEN d.is_recursive_triggers_on = 1 THEN 'X' ELSE '' END AS [is_recursive_triggers_on], 
    /* this should be avoided if possible */
    CASE WHEN d.is_trustworthy_on = 1 THEN 'X' ELSE '' END AS [is_trustworthy_on],
    /* auto shrink should not be on */
    CASE WHEN d.[is_auto_shrink_on] = 1 THEN 'X' ELSE '' END AS [is_auto_shrink_on]
FROM sys.databases d
WHERE d.database_id NOT IN (1, 2, 4)
    AND (
        d.owner_sid <> 0x01 
        OR d.collation_name <> @desired_collation
        OR d.is_auto_close_on = 1
        OR d.page_verify_option_desc <> 'CHECKSUM' 
        OR d.is_auto_create_stats_on = 0 
        OR d.is_quoted_identifier_on = 0 
        OR d.is_numeric_roundabort_on = 1
        OR d.is_recursive_triggers_on = 1
        OR d.is_trustworthy_on = 1 
        OR d.[is_auto_shrink_on] = 1
    )
ORDER BY d.name

/****************************************************************************************************/
SELECT 'OBJECTS' AS [container] 
/****************************************************************************************************/
IF OBJECT_ID('tempdb..#objects') IS NOT NULL BEGIN 
    DROP TABLE #objects 
END

CREATE TABLE #objects (
    [database_name] nvarchar(128) NULL,
    [schema_name] nvarchar(128) NULL,
    [object_name] nvarchar(128) NULL,
    [object_type] nvarchar(60) NULL,
    [column_name] nvarchar(128) NULL,
    [uses_quoted_identifier] char(1) NULL,
    [uses_ansi_nulls] char(1) NULL,
    [is_ansi_padded] char(1) NULL
)

INSERT INTO [#objects] (
    [database_name],
    [schema_name],
    [object_name],
    [object_type],
    [column_name],
    [uses_quoted_identifier],
    [uses_ansi_nulls],
    [is_ansi_padded]
)
EXEC sys.sp_MSforeachdb N'USE [?]; 
    IF DB_ID() <= 4 RETURN
    DECLARE @bad_value CHAR(1) = ''X''
    SELECT
        DB_NAME() AS [database_name],
        OBJECT_SCHEMA_NAME(o.object_id) AS [schema_name], 
        OBJECT_NAME(o.object_id) AS [object_name], 
        o.type_desc AS [object_type], 
        NULL AS [column_name], 
        CASE OBJECTPROPERTY(o.object_id, ''ExecIsQuotedIdentOn'') WHEN 0 THEN @bad_value ELSE '''' END AS [uses_quoted_identifier], 
        CASE OBJECTPROPERTY(o.object_id, ''ExecIsAnsiNullsOn'') WHEN 0 THEN @bad_value ELSE '''' END AS [uses_ansi_nulls], 
        '''' AS [is_ansi_padded]
    FROM sys.objects AS o
    WHERE 0 IN (
        OBJECTPROPERTY(o.object_id, ''ExecIsQuotedIdentOn''), 
        OBJECTPROPERTY(o.object_id, ''ExecIsAnsiNullsOn'')
    )'

INSERT INTO [#objects] (
    [database_name],
    [schema_name],
    [object_name],
    [object_type],
    [column_name],
    [uses_quoted_identifier],
    [uses_ansi_nulls],
    [is_ansi_padded]
) 
EXEC sys.sp_MSforeachdb N'USE [?]; 
    IF DB_ID() <= 4 RETURN
    DECLARE @bad_value CHAR(1) = ''X''
    -- the OBJECTPROPERTY does not work for tables with ''ExecIsAnsiNullsOn''
    SELECT 
        DB_NAME() AS [database_name],
        OBJECT_SCHEMA_NAME(t.object_id) AS [schema_name], 
        OBJECT_NAME(t.object_id) AS [object_name], 
        ''TABLE'' AS [object_type], 
        NULL AS [column_name], 
        '''' AS [uses_quoted_identifier], 
        CASE t.[uses_ansi_nulls] WHEN 0 THEN @bad_value ELSE '''' END AS [uses_ansi_nulls], 
        '''' AS [is_ansi_padded]
    FROM sys.[tables] AS [t] 
    WHERE [t].[uses_ansi_nulls] = 0'
    
INSERT INTO [#objects] (
    [database_name],
    [schema_name],
    [object_name],
    [object_type],
    [column_name],
    [uses_quoted_identifier],
    [uses_ansi_nulls],
    [is_ansi_padded]
)
EXEC sys.sp_MSforeachdb N'USE [?]; 
    IF DB_ID() <= 4 RETURN
    DECLARE @bad_value CHAR(1) = ''X''
    SELECT
        DB_NAME() AS [database_name],
        OBJECT_SCHEMA_NAME(t.object_id) AS [schema_name], 
        OBJECT_NAME(t.object_id) AS [object_name], 
        ''COLUMN'' AS [object_type], 
        c.name AS [column_name], 
        '''' AS [uses_quoted_identifier], 
        '''' AS [uses_ansi_nulls], 
        CASE c.[is_ansi_padded] WHEN 0 THEN @bad_value ELSE '''' END AS [is_ansi_padded]
    FROM sys.tables AS t
    JOIN sys.columns AS c ON c.object_id = t.object_id
    JOIN sys.types AS ty ON ty.system_type_id = c.system_type_id AND ty.user_type_id = c.user_type_id
    WHERE c.is_ansi_padded = 0 
        AND ty.name IN (''varbinary'',''BINARY'',''varchar'',''CHAR'')'

SELECT 
    [o].[database_name],
    [o].[schema_name],
    [o].[object_name],
    [o].[object_type],
    [o].[column_name],
    [o].[uses_quoted_identifier],
    [o].[uses_ansi_nulls],
    [o].[is_ansi_padded] 
FROM [#objects] AS [o] 
ORDER BY [o].[database_name], 
    [o].[schema_name],
    [o].[object_name]

