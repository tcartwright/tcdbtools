# Find-DBInvalidSettings
**Author** Tim Cartwright

## Synopsis
Finds settings and options that may or may not be invalid depending upon design choices. They are typically invalid however. 

## Description
Finds settings and options that may or may not be invalid depending upon design choices. They are typically invalid however. Any option marked with an X will typically have a non-standard setting, and or may not be an issue and should be investigated. This function does not fix any invalid settings. That is left to the DBA.

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

### Example

```powershell
$result = Find-DBInvalidSettings -ServerInstance "ServerName" 

$result.ServerInstance
$result.ServerOptions    | Format-Table
$result.ServerSettings   
$result.FileGrowths      | Format-Table 
$result.DatabaseSettings | Format-Table
$result.DatabaseObjects  | Format-Table
```

[Back](/README.md)
