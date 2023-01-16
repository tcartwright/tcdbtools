# Invoke-DBMoveIndexes
**Author** Tim Cartwright

## Synopsis
Moves indexes from one file group to another including heaps.

## Description
Moves indexes from one file group to another. Both file groups must exist, neither will be created for you. As the indexes are moved, they will be rebuilt.

## Syntax
    Invoke-DBMoveIndexes 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [[-Credentials] <PSCredential>] 
        [-SourceFileGroupName] <String> 
        [-TargetFileGroupName] <String> 
        [[-IndexMoveTimeout] <Int32>] 
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

        Required?                    true
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
        The amount of time that controls how long a index move can run 
        before timing out.
        
        NOTES: This timeout is in minutes.

        Required?                    false
        Position?                    6
        Default value                5
        Accept pipeline input?       false
        Accept wildcard characters?  false


[Back](/README.md)