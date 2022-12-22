# New-DBSqlConnection
**Author** Tim Cartwright

## Synopsis
Creates a SqlConnection

## Description
Creates a SqlConnection

## Syntax
    New-DBSQLConnection 
        [-ServerInstance] <String> 
        [-Database] <String> 
        [[-Credentials] <PSCredential>] 
        [[-AppName] <String>] 
        [<CommonParameters>]

## Parameters
    -ServerInstance <String>
        Specifies the database server hostname.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Database <String>
        Specifies the name of the database.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -AppName <String>
        The application name that will be supplied to the connection.

        Required?                    false
        Position?                    4
        Default value                tcdbtools
        Accept pipeline input?       false
        Accept wildcard characters?  false

[Back](/README.md)