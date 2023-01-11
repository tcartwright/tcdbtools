# Find-DBInvalidSettings
**Author** Tim Cartwright

## Synopsis
Finds settings and options that may or may not be invalid depending upon design choices. They are typically invalid however and should be investigated.

## Description
Finds settings and options that may or may not be invalid depending upon design choices. They are typically invalid however and should be investigated. Any option marked with an X will typically have a non-standard setting, and or may not be an issue and should be investigated. This function does not fix any invalid settings. That is left to the DBA.

## Settings Inspected

### Server Options
These settings are normally off, and if an X appears in the setting_value column then that setting has been enabled and will affect the entire server. Unless that is desired, it should be investigated.

| setting_name | validation |
| ---- | ---- |
|DISABLE_DEF_CNST_CHK | <> 0 |
|IMPLICIT_TRANSACTIONS | <> 0 |
|CURSOR_CLOSE_ON_COMMIT | <> 0 |
|ANSI_WARNINGS | <> 0 |
|ANSI_PADDING | <> 0 |
|ANSI_NULLS | <> 0 |
|ARITHABORT | <> 0 |
|ARITHIGNORE | <> 0 |
|QUOTED_IDENTIFIER | <> 0 |
|NOCOUNT | <> 0 |
|ANSI_NULL_DFLT_ON | <> 0 |
|ANSI_NULL_DFLT_OFF | <> 0 |
|CONCAT_NULL_YIELDS_NULL | <> 0 |
|NUMERIC_ROUNDABORT | <> 0 |
|XACT_ABORT | <> 0 | 

### Server Settings
Server settings each have different validations.  If any of the validations are true, then an X will appear in the results. These validations may or may not fall in line with your exact specific design. 

| setting_name | validation |
| ---- | ---- |
| affinity_mask | <> 0 |
| affinity_IO_mask | <> 0 |
| affinity64_mask | <> 0 |
| affinity64_IO_mask | <> 0 |
| cost_of_parallelism | < 20 OR > 100 |
| cross_db_owner_chaining | = 1 |
| default_trace | = 0 |
| disallow_results_from_triggers | <> 0 |
| fill_factor | <> 0 |
| locks | <> 0 |
| max_dop | < 2 OR > 32 |
| max_server_memory_MB | < 2000 |
| ole_automation | = 1 |
| user_connections | <> 0 |
| user_options | <> 0 |
| xp_cmdshell | = 1 |
| collation_name | <> "Your Collation" |

## Database File Growths
Database file growths are scanned for these rules:
* Is the file using a percentage growth?
* Is the growth MB < 64 MB OR > 2000 MB

Any file found to be true for these rules will show up in the list.

| name | description |
| ---- | ---- |
| db_name | Name of the database |
| file_name | The database file name |
| growth_kb | The growth of the file in KB |
| growth_mb | The growth of the file in MB |
| is_percent_growth | If the file is using percentage growth |

## Database
Database settings each have different validations.  If any of the validations are true, then an X will appear in the results. These validations may or may not fall in line with your exact specific design. 

| setting_name | validation |
| ---- | ---- |
| owner_sid | <> 'sa' |
| collation_name | <> "Your Collation" |
| is_auto_close_on | = 1 |
| page_verify_option_desc | <> 'CHECKSUM' |
| is_auto_create_stats_on | = 0 |
| is_quoted_identifier_on | = 0 |
| is_numeric_roundabort_on | = 1 |
| is_recursive_triggers_on = | = 1 |
| is_trustworthy_on | = 1 |
| is_auto_shrink_on | = 1 |

## Database Objects
All user defined database objects are inspected for various SET options that were in place when the object was created. Certain SET options apply to certain objects. If any of them are invalid an X will appear in one of the values marked with a question mark. Any object found with invalid SET options should be recreated with valid SET options.

| name | description |
| ---- | ---- |
| database_name | Name of the database |
| schema_name | Schema name of the object |
| object_name | Name of the object |
| object_type | Object Type |
| column_name | Column name, if applicable |
| [uses_quoted_identifier](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-quoted-identifier-transact-sql?view=sql-server-ver16) | ? |
| [uses_ansi_nulls](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-ansi-nulls-transact-sql?view=sql-server-ver16) | ? |
| [is_ansi_padded](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-ansi-padding-transact-sql?view=sql-server-ver16) | ? |

## Syntax
    Find-DBInvalidSettings 
        [-ServerInstance] <String> 
        [[-Credentials] <PSCredential>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        The sql server instance to connect to.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CollationName <String>
        The collation name you expect your server and databases to be using. Defaults to "SQL_Latin1_General_CP1_CI_AS"        

        Required?                    false
        Position?                    3
        Default value                SQL_Latin1_General_CP1_CI_AS
        Accept pipeline input?       false
        Accept wildcard characters?  false



### Example

```powershell
$result = Find-DBInvalidSettings -ServerInstance "ServerName" 

$result.ServerInstance
$result.ServerOptions    | Format-Table
$result.ServerSettings   | Format-Table
$result.FileGrowths      | Format-Table 
$result.DatabaseSettings | Format-Table
$result.DatabaseObjects  | Format-Table
```

[Back](/README.md)
