# Invoke-DBMoveIndexes
**Author** Tim Cartwright

## Synopsis
Moves indexes from one file group to another including heaps.

## Description
Moves indexes from one file group to another. Both file groups must exist, neither will be created for you. As the indexes are moved, they will be rebuilt.

## Notes
All of the include and exclude parameters are OR'ed together in the following order:

- ExcludeIndexes
- IncludeIndexes
- ExcludeTables
- IncludeTables
- ExcludeSchemas
- IncludeSchemas

## Syntax
    Invoke-DBMoveIndexes 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [[-Credentials] <PSCredential>] 
        [[-SourceFileGroupName] <String>] 
        [-TargetFileGroupName] <String> 
        [[-IndexMoveTimeout] <Int32>] 
        [[-IncludeSchemas] <String[]>] 
        [[-ExcludeSchemas] <String[]>] 
        [[-IncludeTables] <String[]>] 
        [[-ExcludeTables] <String[]>] 
        [[-IncludeIndexes] <String[]>] 
        [[-ExcludeIndexes] <String[]>] 
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
        The databases to move indexes in.

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

    -SourceFileGroupName <String>
        The file group name to move indexes from.

        Required?                    false
        Position?                    4
        Default value                PRIMARY
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -TargetFileGroupName <String>
        The file group where the indexes will be moved to.

        Required?                    true
        Position?                    5
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IndexMoveTimeout <Int32>
        The amount of time that controls how long a index move can run before timing out.
        
        NOTES: This timeout is in minutes.

        Required?                    false
        Position?                    6
        Default value                5
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeSchemas <String[]>
        A list of schemas to include in the move. If not provided then all schemas will be returned.

        Required?                    false
        Position?                    7
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ExcludeSchemas <String[]>
        A list of schemas to exclude from the move.

        Required?                    false
        Position?                    8
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeTables <String[]>
        A list of tables to include in the move. If not provided then all tables will be returned.

        Required?                    false
        Position?                    9
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ExcludeTables <String[]>
        A list of tables to exclude from the move.

        Required?                    false
        Position?                    10
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeIndexes <String[]>
        A list of indexes to include in the move. If not provided then all tables will be returned.

        Required?                    false
        Position?                    11
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ExcludeIndexes <String[]>
        A list of indexes to exclude from the move.

        Required?                    false
        Position?                    12
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

<br/>
<br/>
  
[Back](/README.md)
