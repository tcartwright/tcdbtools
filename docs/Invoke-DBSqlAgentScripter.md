# Invoke-DBSqlAgentScripter
**Author** Tim Cartwright

## Synopsis
Will script out all Sql Agent objects to sql script files.

## Description
Will script out all Sql Agent objects to sql script files.

## Syntax
    Invoke-DBSqlAgentScripter 
        [-ServerInstances] <String[]> 
        [[-Credentials] <PSCredential>] 
        [[-OutputPath] <DirectoryInfo>] 
        [-DoNotScriptJobDrop ] 
        [-IncludeIfNotExists ] 
        [-DoNotGenerateForSqlCmd ] 
        [<CommonParameters>]

## Parameters
    -ServerInstances <String[]>
        The sql server instances to connect to.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied then a 
        trusted connection will be used.

        Required?                    false
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -OutputPath <DirectoryInfo>
        The output path for the scripts.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DoNotScriptJobDrop <SwitchParameter>
        APPLIES TO JOBS ONLY: if this switch is present, then jobs wills be scripted 
        without a drop.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeIfNotExists <SwitchParameter>
        If this switch is present an IF NOT EXISTS WILL be added to all scripts so they 
        will only get created if they don't already exist

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DoNotGenerateForSqlCmd <SwitchParameter>
        If this switch is present then $ tokens in the script will be left alone. Else they 
        will be replaced with a token that will work for SqlCmd.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

### Example

```powershell
Invoke-DBSqlAgentScripter -ServerInstances "server1", "server2" -OutputPath "C:\temp\SqlAgentPS\Output" -InformationAction Continue
```

[Back](/README.md)