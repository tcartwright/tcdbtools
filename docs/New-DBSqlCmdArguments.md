# New-DBSqlCmdArguments
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/helpers/New-DBSqlCmdArguments.ps1)

## Synopsis
Creates a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.

## Description
Creates a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.

## Syntax
    New-DBSqlCmdArguments 
        [[-ServerInstance] <String>] 
        [[-Credentials] <PSCredential>] 
        [[-ApplicationName] <String>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        The sql server instance to connect to.

        Required?                    false
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used.

        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ApplicationName <String>
        The name of the application associated with the connection string.

        Required?                    false
        Position?                    6
        Default value                tcdbtools
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example

```powershell
# this object can be splatted to Invoke-SqlCmd or other functions 
# that take the same parameters
$SqlCmdArguments = New-DBSqlCmdArguments `
    -ServerInstance "ServerName" `
    -InformationAction Continue

Invoke-SqlCmd @SqlCmdArguments -Query "SELECT @@SERVERNAME"
```

<br/>
<br/>
  
[Back](/README.md)
