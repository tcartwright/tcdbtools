# Get-DBUserCredential
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/credentials/Get-DBUserCredential.ps1)

## Synopsis
Gets the credential stored under the application name.

## Description
Gets the credential stored under the application name.

## Syntax
    Get-DBUserCredential 
        [-ApplicationName] <string> 
        [<CommonParameters>]

## Parameters
    -ApplicationName <String>
        The application name the credentials will be saved under.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Outputs
The credentials for the application name.

### Example

```powershell
$creds = Get-DBUserCredential -ApplicationName "TimsTest"
# now these creds can be passed into any of the functions
```

<br/>
<br/>
  
[Back](/README.md)
