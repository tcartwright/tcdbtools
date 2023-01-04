# Invoke-DBExtractCLRDLL
**Author** Tim Cartwright

## Synopsis
Will extract all user defined files from SQL SERVER database as DLL files, and or PDB files. 

## Description
Will extract all user defined files from SQL SERVER database as DLL files, and or PDB files. 

## Syntax
    Invoke-DBExtractCLRDLL 
        [-ServerInstance] <String> 
        [-Database] <String> 
        [[-SavePath] <DirectoryInfo>] 
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

    -Database <String>
        The database containing the CLR dlls.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SavePath <DirectoryInfo>
        Specifies the directory where you want to store the generated dll object. If the 
        SavePath is not supplied, then the users temp directory will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied then a 
        trusted connection will be used.

        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

[Back](/README.md)