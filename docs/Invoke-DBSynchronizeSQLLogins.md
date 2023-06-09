# Invoke-DBSynchronizeSQLLogins
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/Invoke-DBSynchronizeSQLLogins.ps1)

## Synopsis
Will synchronize sql logins between servers. Synchronizes both the [HASHED](https://sqlity.net/en/2344/create-login-with-hashed-password/) password and the SID.
Very useful for synchronizing logins between Availability Group Servers. SA and DBO are not synchronized.

## Description
Will synchronize sql logins between servers. Synchronizes:
    
- [HASHED](https://sqlity.net/en/2344/create-login-with-hashed-password/) password
- SID
- Default Database
- Default Language
    
The password hashes are backwards compatible, but they are not forward compatible. That means that if you script out
the login on an older server it will NOT be deployable against a newer server. If you have a mix of older and newer
servers, it is advised you use the AuthorityServer method, and have your logins synchronize out from there.

## Synchronization Methods
There are two methods of determining what logins will be scripted out:

- Default method: By default all logins will be compared with the same login name, and the login with the latest modified date will be chosen to be deployed to all the servers.
- Authority Server method: This method will only use a single server as the source for all logins to be deployed out. 
  - Example: if an authorityServer of "server1" is passed in, then only logins from "server1" will be scripted, and then deployed to all the other servers.
  - Extra logins that are not on the AuthorityServer are ignored when scripted out, and not dropped. Only logins available on the
AuthorityServer are synchronized.

## Syntax
    Invoke-DBSynchronizeSQLLogins 
        [-Servers] <DBServer[]> 
        [[-IgnoreRegex] <String>] 
        [[-AuthorityServer] <String>] 
        [-DoNotAddAutoFix ] 
        [-DropIfExists ] 
        [-DoNotInvoke ] 
        [[-CreateAlterLoginSqlOutputVar] <PSReference>] 
        [<CommonParameters>]

## Parameters
    -Servers <DBServer[]>
        Collection of server / database names to run the query against. An array of type TCDbTools.DbServer.
        
        NOTE: The ctor has this signature:
        public DBServer(string serverInstance, string database = "master", PSCredential credentials = null)

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IgnoreRegex <String>
        A regex that will be applied to all of the login names. Any name that matches the regex will be ignored and not scripted out.

        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -AuthorityServer <String>
        The authority server to use for scripting logins. When null all logins from all servers will be compared using the latest modified
        date. When a valid value is passed in, then only logins from the AuthorityServer will be scripted and deployed.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DoNotAddAutoFix <SwitchParameter>
        By default a script is added to the end of each login to auto fix all of the database users. Uses sp_MSForeachdb to
        loop all of the databases. Passing this switch in will disable that part of the script generation.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DropIfExists <SwitchParameter>
        Normally a login is only dropped if found, but the SID is different. If this switch is present, then the login is always
        dropped and recreated.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DoNotInvoke <SwitchParameter>
        When this switch is enabled then the script that is generated is NOT executed against the servers.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CreateAlterLoginSqlOutputVar <PSReference>
        Allows for capture of the sql that is run by use of a [ref] parameter. See examples.

        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

## Outputs
A table of the servers updated, and the logins synched to each and whether deploying to that server was successful.

Optionally a reference parameter can be utilized to grab the login alter / create sql.        


### Example 
Uses the authority server to synchronize logins to the other servers
```powershell
$authorityServer = "server1"

$serverList = @()

$serverList += [TCDbTools.DBServer]::new("server1")
$serverList += [TCDbTools.DBServer]::new("server2")
$serverList += [TCDbTools.DBServer]::new("server3")

$retVal = Invoke-DBSynchronizeSQLLogins -Servers $serverList -AuthorityServer $authorityServer -InformationAction Continue
$retVal
```

### Example 
Grabs the latest logins from each server to synchronize to the other servers. Ignores any logins with an underscore in the name.
```powershell
$serverList = @()

$serverList += [TCDbTools.DBServer]::new("server1")
$serverList += [TCDbTools.DBServer]::new("server2")
$serverList += [TCDbTools.DBServer]::new("server3")

$retVal = Invoke-DBSynchronizeSQLLogins -Servers $serverList -InformationAction Continue -IgnoreRegex "^[^_]*?_.*"
$retVal
```

### Example 
Generates the change sql, but does not run it against the server list. Grabs the sql into a variable.
```powershell
$serverList = @()

$serverList += [TCDbTools.DBServer]::new("server1")
$serverList += [TCDbTools.DBServer]::new("server2")
$serverList += [TCDbTools.DBServer]::new("server3")

[string]$loginSql = ""

$retVal = Invoke-DBSynchronizeSQLLogins -Servers $serverList -DoNotInvoke -InformationAction Continue -CreateAlterLoginSqlOutputVar ([ref]$loginSql)
$retVal
$loginSql
```

### Example 
An example of the script that is generated for a single login when DoNotAddAutoFix is not enabled, and DropIfExists is not enabled.
    
The password has been truncated.
```sql
DECLARE @checked BIT = 0
/******************************************************************************************************************************************/
/******************************* Login: FOO generated from: SERVER1 on: 2023-05-01 15:49:32 ***********************************************/
/******************************************************************************************************************************************/
SET @checked = (SELECT [is_policy_checked] FROM sys.sql_logins WHERE name = 'FOO')
IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = OFF END
IF NOT EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = 'FOO' AND sp.sid = 0xA5D09CAA8D73364BBEBC172F0C033C64) BEGIN
    RAISERROR('********************************[FOO]********************************', 0, 1) WITH NOWAIT;
    IF EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = 'FOO') BEGIN;
        RAISERROR('DROPPING LOGIN [FOO]', 0, 1) WITH NOWAIT;
        DROP LOGIN [FOO];
    END;
    RAISERROR('CREATING LOGIN [FOO]', 0, 1) WITH NOWAIT;
    CREATE LOGIN [FOO]
            WITH PASSWORD = 0x02001867BC72D30F... HASHED,
            DEFAULT_DATABASE = [master],
            DEFAULT_LANGUAGE = [us_english],
            SID = 0xA5D09CAA8D73364BBEBC172F0C033C64;
END ELSE BEGIN
    RAISERROR('ALTERING LOGIN [FOO]', 0, 1) WITH NOWAIT;
    ALTER LOGIN [FOO]
        WITH PASSWORD = 0x02001867BC72D30F... HASHED,
        DEFAULT_DATABASE = [master],
        DEFAULT_LANGUAGE = [us_english];
END

RAISERROR('AUTO FIXING LOGIN [FOO]', 0, 1) WITH NOWAIT;
EXEC sys.sp_MSForeachdb N'
    USE [?];
    IF EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = ''?'' AND d.is_read_only = 0) BEGIN
        IF EXISTS (SELECT 1 FROM sys.database_principals dp WHERE dp.name = ''FOO'') BEGIN
            EXEC sys.sp_change_users_login @Action = ''Update_One'', @UserNamePattern = ''FOO'', @LoginName = ''FOO''
        END
    END
'

IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = ON END;
```

### Example 
An example of the script that is generated for a single login when DoNotAddAutoFix is enabled, and DropIfExists is enabled.
    
The password has been truncated.
```sql
DECLARE @checked BIT = 0;
/******************************************************************************************************************************************/
/******************************* Login: FOO generated from: SERVER1 on: 2023-05-01 15:49:32 ***********************************************/
/******************************************************************************************************************************************/
SET @checked = (SELECT [is_policy_checked] FROM sys.sql_logins WHERE name = 'FOO')
IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = OFF END

RAISERROR('********************************[FOO]********************************', 0, 1) WITH NOWAIT;
IF EXISTS(SELECT 1 FROM sys.server_principals sp WHERE sp.name = 'FOO') BEGIN;
    RAISERROR('DROPPING LOGIN [FOO]', 0, 1) WITH NOWAIT;
    DROP LOGIN [FOO];
END;
RAISERROR('CREATING LOGIN [FOO]', 0, 1) WITH NOWAIT;
CREATE LOGIN [FOO]
        WITH PASSWORD = 0x02001867BC72D30F... HASHED,
        DEFAULT_DATABASE = [master],
        DEFAULT_LANGUAGE = [us_english],
        SID = 0xA5D09CAA8D73364BBEBC172F0C033C64;

IF @checked = 1 BEGIN ALTER LOGIN [FOO] WITH CHECK_POLICY = ON END;
```

<br/>
<br/>
  
[Back](/README.md)
