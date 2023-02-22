# Invoke-DBScriptObjects
**Author** Phil Factor

**Edits By** Tim Cartwright

[Source Code](/tcdbtools/functions/Invoke-DBScriptObjects.ps1)

## Synopsis
Generate file-per-object scripts of specified server and database.

## Description
Generate file-per-object scripts of specified server and database to specified directory. Attempts to create specified directory if not found.

## NOTES
Adapted from [Automated Script-generation with Powershell and SMO][def]

Editor: Tim Cartwright:
- Changed to script Service Broker objects.
- Script into folders per object type and schema, instead of one flat folder
- Ability to use username and password instead of trusted. Trusted can still be used.

        Example directory structure created:
            ├───dbo
            │   ├───StoredProcedures
            │   │       dbo.proc1.sql
            │   │       dbo.proc2.sql
            │   │       ...
            │   ├───Tables
            │   │       dbo.table1.sql
            │   │       dbo.table2.sql
            │   │       ...
            │   └───Views
            │   │       dbo.view1.sql
            │   │       dbo.view2.sql
            │   │       ...


## Syntax
    Invoke-DBScriptObjects 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [-SavePath] <String> 
        [-Credentials <PSCredential>] 
        [-Scripter <Scripter>]
        [<CommonParameters>] 

## Parameters
    -ServerInstance <String>

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Databases <String[]>
        Specifies the name of the databases you want to script. Each database 
        will be scripted to its own directory. If the value ALL_USER_DATABASES 
        is passed in then, the renames will be applied to all user databases.

        Required?                    true
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used.

        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Scripter <Scripter>
        An object of type [Microsoft.SqlServer.Management.Smo.Scripter]. Allows 
        for custom scripter options to be set. If not provided a default 
        scripter will be created. Can be created using New-DBScripterObject and 
        then customized.

        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SavePath <String>
        Specifies the directory where you want to store the generated scripts. 
        If the SavePath is not supplied, then the users temp directory will be 
        used.

        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example 
If you need to ignore names of certain types, you can define a variable that follows this pattern $ignore + Type that is of type Regex. Any object name that matches will not be scripted.

EX: Say that you wanted to ignore certain domain users, you could define the following variable before calling the function: 

```powershell
$ignoreUsers = ".*DomainName.*" 
Invoke-DBScriptObjects ` 
    -ServerInstance "ServerName" `
    -Databases "DatabaseName" `
    -SavePath "C:\db_scripts" `
    -InformationAction Continue
```
To ignore other types just define more variables, like $ignoreStoredProcedures or $ignoreTables

### Example 
Creating a customized scripter that ignores extended properties:
        
```powershell
$scripter = New-ScripterObject -ServerInstance "ServerName"
$Scripter.Options.ExtendedProperties = $false
Invoke-DBScriptObjects `
    -ServerInstance "ServerName" `
    -Databases "DatabaseName1", "DatabaseName2" `
    -SavePath "C:\db_scripts" `
    -Scripter $scripter `
    -InformationAction Continue
```

### Example 
Scripting all user databases:
        
```powershell
$scripter = New-ScripterObject -ServerInstance "ServerName"
$Scripter.Options.ExtendedProperties = $false
Invoke-DBScriptObjects `
    -ServerInstance "ServerName" `
    -Databases "ALL_USER_DATABASES" `
    -SavePath "C:\db_scripts" 
    -InformationAction Continue
```

<br/>
<br/>
  
[Back](/README.md)


[def]: http://www.simple-talk.com/sql/database-administration/automated-script-generation-with-powershell-and-smo/