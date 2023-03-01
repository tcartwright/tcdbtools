# Invoke-DBMoveIndexes
**Author** Tim Cartwright

[Source Code](/tcdbtools/functions/Invoke-DBMoveIndexes.ps1)

## Synopsis
Moves indexes from one file group to another including heaps.

## Description
Moves indexes from one file group to another. Both file groups must exist, neither will be created for you. As the indexes are moved, they will be rebuilt.

## Notes
These types of objects are moved:
- Clustered Indexes
- Non-Clustered Indexes
- Heaps
- LOB Data


All of the include and exclude parameters are OR'ed together in the following order if any values are passed in for any of these parameters:
- ExcludeIndexes
- IncludeIndexes
- ExcludeTables
- IncludeTables
- ExcludeSchemas
- IncludeSchemas

This provides a lot of flexibility in narrowing the list down, but could also exclude indexes from the results you did not wish to exclude.

So, if all of include / exclude parameters are supplied then the resulting SQL where clause to find the indexes should look similar to this:

```sql
WHERE OBJECTPROPERTY(i.[object_id], 'IsUserTable') = 1
    AND [f].[name] = 'file_group_name'
    AND (
        i.[name] NOT IN ('ExcludeIndexes1', 'ExcludeIndexes2', '...')
        OR i.[name] IN ('IncludeIndexes1', 'IncludeIndexes2', '...')
        OR i.[object_id] NOT IN (OBJECT_ID('ExcludeTables1'), OBJECT_ID('ExcludeTables2'), OBJECT_ID('...'))
        OR i.[object_id] IN (OBJECT_ID('IncludeTables1'), OBJECT_ID('IncludeTables2'), OBJECT_ID('...'))
        OR OBJECT_SCHEMA_NAME(i.[object_id]) NOT IN ('ExcludeSchemas1', 'ExcludeSchemas2', '...')
        OR OBJECT_SCHEMA_NAME(i.[object_id]) IN ('IncludeSchemas1', 'IncludeSchemas2', '...')
    )
```


## Syntax
    Invoke-DBMoveIndexes 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [[-Credentials] <PSCredential>] 
        [[-SourceFileGroupName] <String>] 
        [-TargetFileGroupName] <String> 
        [-Online ] 
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
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used.

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

    -Online <SwitchParameter>
        Specifies whether underlying tables and associated indexes are available 
        for queries and data modification during the index operation. The default 
        is OFF.

        Required?                    false
        Position?                    named
        Default value                False
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
        A list of schemas to include in the move. If not provided then all schemas 
        will be returned.

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
        A list of tables to include in the move. If not provided then all tables 
        will be returned.

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
        A list of indexes to include in the move. If not provided then all 
        tables will be returned.

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


## Examples

### Example
Move all of the indexes in the dbo schema. All other schemas will be ignored.
    
```powershell
Invoke-DBMoveIndexes `
    -ServerInstance "ServerName" `
    -Databases "DatabaseName1", "DatabaseName2" `
    -IncludeSchemas "dbo"
```

### Example
Move all of the indexes for a specific set of tables except for the PK of each table.
    
```powershell
Invoke-DBMoveIndexes `
    -ServerInstance "ServerName" `
    -Databases "DatabaseName1" `
    -IncludeTables "dbo.Table1", "dbo.Table2" `
    -ExcludeIndexes "PK_Table1", "PK_Table2"
```

<br/>
<br/>
  
[Back](/README.md)
