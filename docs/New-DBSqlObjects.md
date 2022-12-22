# New-DBSqlObjects
**Author** Tim Cartwright

## Synopsis
Creates two objects that can be used for connectivity.

## Description
Creates two objects that can be used for connectivity.

Creates two objects:
* The first is a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.
* The second is a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections


## Syntax
    New-DBSqlObjects 
        [[-ServerInstance] <String>] 
        [[-Credentials] <PSCredential>] 
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
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example

```powershell
$objects = New-DBSqlObjects -ServerInstance "ServerName"
$server = $objects.Server                       # this is the SMO connection object
$sqlCmdArguments = $objects.SqlCmdArguments     # this object can be splatted to Invoke-SqlCmd or other functions that take the same parameters
```

[Back](/README.md)