# New-DBSMOServer
**Author** Tim Cartwright

## Synopsis
Creates a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections.

## Description
Creates a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections.


## Syntax
    New-DBSMOServer 
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
# this is the SMO server object
$server = New-DBSMOServer -ServerInstance "ServerName"
```

[Back](/README.md)