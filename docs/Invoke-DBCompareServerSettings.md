# Invoke-DBCompareServerSettings
**Author** Tim Cartwright

## Synopsis
Compares all server settings for each instance passed in to generate a report showing differences. The user options are also compared individually. Any user option will have its name suffixed with (options).

## Description
Compares all server settings for each instance passed in to generate a report showing differences.

## Syntax
    Invoke-DBCompareServerSettings 
        [-ServerInstances] <String[]> 
        [[-Credentials] <PSCredential>] 
        [-IgnoreVersionDifferences ] 
        [<CommonParameters>]

## Parameters
    -ServerInstances <String[]>
        The sql server instances to connect to and compare.  At least two 
		servers must be passed in.

        Required?                    true
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

    -IgnoreVersionDifferences <SwitchParameter>
        If a SQL Server does not support a particular setting because it is an 
		older version  then the value will be a dash: "-". If this switch is 
		present, then any setting value with a dash will not be considered a 
		difference.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

[Back](/README.md)