# Set-DBUserCredential
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/credentials/Set-DBUserCredential.ps1)

## Synopsis
Saves a user credential to the Windows Credential Manager that can be retried later, and passed in to functions that require credentials.

## Description
Saves a user credential to the Windows Credential Manager that can be retried later, and passed in to functions that require credentials. Should be run to store the credentials, but not saved into a script. That way you can keep from storing passwords into your scripts.

## Notes    
Removal of credentials can be done by accessing the Credential Manager UI from windows.

[Accessing Credential Manager](https://support.microsoft.com/en-us/windows/accessing-credential-manager-1b5c916a-6a16-889f-8581-fc16e8165ac0#:~:text=Credential%20Manager%20lets%20you%20view,select%20Credential%20Manager%20Control%20panel.)

## Syntax
    Set-DBUserCredential 
        [-ApplicationName] <String> 
        [-UserName] <String> 
        [-Password] <String> 
        [<CommonParameters>]

## Parameters
    -ApplicationName <String>
        The application name the credentials will be saved under.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -UserName <String>
        The user name for the credential.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Password <String>

        Required?                    true
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example

```powershell
# DO NOT STORE THIS LINE IN YOUR SCRIPTS
Set-DBUserCredential -ApplicationName "TimsTest" -UserName "tcartwright" -Password "my sql password here"
# now these creds can be retrieved using  Get-DBUserCredential in scripts
```

<br/>
<br/>
  
[Back](/README.md)
