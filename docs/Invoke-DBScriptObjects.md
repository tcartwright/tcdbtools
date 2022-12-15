# Invoke-DBScriptObjects
**Author** Tim Cartwright

## Synopsis
Generate file-per-object scripts of specified server and database.

## Description
Generate file-per-object scripts of specified server and database to specified directory. Attempts to create specified directory if not found.

## Syntax
    Invoke-DBScriptObjects 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [-SavePath] <String> 
        [-Credentials <PSCredential>] 
        [<CommonParameters>] 

## Parameters
    -ServerInstance <String>

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Databases <String[]>

        Required?                    true
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SavePath <String>
        Specifies the directory where you want to store the generated scripts.

        Required?                    true
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

[Back](/README.md)