# Invoke-DBRenameConstraints
**Author** Tim Cartwright

## Synopsis
Will rename all indexes and constraints to match naming conventions.


## Description
Will rename all indexes and constraints to match naming conventions. Any constraint name that already matches the expected 
convention will be skipped. Custom naming conventions can be used.

## Syntax
    Invoke-DBRenameConstraints 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [[-Credentials] <PSCredential>] 
        [-IncludeSchemaInNames ] 
        [-Force ] 
        [[-CustomGetObjectName] <ScriptBlock>] 
        [<CommonParameters>]


## Parameters
    -ServerInstance <String>
        The sql server instance to connect to.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Databases <String[]>
        The database.

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

    -IncludeSchemaInNames <SwitchParameter>
        If enabled then all names will include the schema as part of the name.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Force <SwitchParameter>
        If enabled then all constraint names will be renamed even if they match the expected naming conventions.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CustomGetObjectName <ScriptBlock>
        This script block can be passed in to override the naming convention used.
        
        The method signature is as follows: function GetObjectName($obj, [switch]$IncludeSchemaInNames)
        
        Note: Each of the details properties holds different values based upon object type
        
        $obj is an objection with the following properties:
            schema_name: The schema name of the object
            table_name: The name of the view or table parent object
            object_name: The name of the constraint or index.
            details1: 
                C       : The column name used or null if the column could not be determined
                D       : The column name used or null if the column could not be determined
                FK      : The schema of the remote table name
                Index   : The first column used in the index key
                PK      : The first column used in the index key
            details2: 
                C       : NULL
                D       : NULL
                FK      : The table name of the remote table name
                Index   : A full list of the columns used in the index comma delimited
                PK      : A full list of the columns used in the index comma delimited
            details3: 
                C       : NULL
                D       : NULL
                FK      : NULL
                Index   : The detailed type of the index
                PK      : The detailed type of the index
            type: The type of object

        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

[Back](/README.md)