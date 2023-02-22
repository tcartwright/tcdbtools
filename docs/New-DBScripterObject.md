# New-DBScripterObject
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/helpers/New-DBScripterObject.ps1)

## Synopsis
Creates a database scripting object that can be customized and used by [Invoke-DBScriptObjects](/docs/Invoke-DBScriptObjects.md)

## Description
Creates a database scripting object that can be customized and used by [Invoke-DBScriptObjects](/docs/Invoke-DBScriptObjects.md)

## Syntax
    New-DBScripterObject 
        [-ServerInstance] <String> 
        [-Credentials <PSCredential>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        Specifies the database server hostname.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example

```powershell
$scripter = New-ScripterObject `
    -ServerInstance "ServerName" `
    -InformationAction Continue
```

<br/>
<br/>
  
[Back](/README.md)
