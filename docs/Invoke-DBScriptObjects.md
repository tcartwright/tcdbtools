# Invoke-DBScriptObjects
**Author** Phil Factor

**Edits By** Tim Cartwright

## Synopsis
Generate file-per-object scripts of specified server and database.

## Description
Generate file-per-object scripts of specified server and database to specified directory. Attempts to create specified directory if not found.

## NOTES
Adapted from [Automated Script-generation with Powershell and SMO](http://www.simple-talk.com/sql/database-administration/automated-script-generation-with-powershell-and-smo/)

Editor: Tim Cartwright:
- Changed to script Service Broker objects.
- Script into folders per object type and schema, instead of one flat folder
- Ability to use username and password instead of trusted. Trusted can still be used.

        Example directory structure created:
            ├───dbo
            │   ├───StoredProcedures
            │   │       dbo.proc1.sql
            │   │       dbo.proc2.sql
            │   │		...
            │   ├───Tables
            │   │       dbo.table1.sql
            │   │       dbo.table2.sql
            │   │       ...
            │   └───Views
            │   │       dbo.view1.sql
            │   │       dbo.view2.sql
            │   │       ...


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