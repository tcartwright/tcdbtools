DECLARE @options TABLE ([name] nvarchar(35), [minimum] int, [maximum] int, [config_value] int, [run_value] int)
DECLARE @optionsCheck TABLE([id] int NOT NULL IDENTITY, [setting_name] varchar(128))
DECLARE @current_value INT;

INSERT INTO @options ([name], [minimum], [maximum], [config_value], [run_value])
EXEC sp_configure 'user_options';

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

SELECT [name], [value]
FROM sys.configurations c
    UNION ALL
SELECT CONCAT(oc.[setting_name], ' (options)'),
    [server_option] = CASE WHEN (@current_value & fn.[value]) = fn.[value] THEN 1 ELSE 0 END
FROM @optionsCheck oc
CROSS APPLY (
    SELECT [value] = CASE WHEN oc.id > 1 THEN POWER(2, oc.id - 1) ELSE 1 END
) fn
    