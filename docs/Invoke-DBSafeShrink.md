
# Invoke-DBSafeShrink
**Author** Tim Cartwright

## Synopsis
Shrinks a Sql Server mdf database file while also rebuilding the indexes. 

## Description
Shrinks a Sql Server mdf database file while also rebuilding the indexes. Can be used to migrate indexes to a new filegroup, or just shrink and move the indexes back to the original filegroup after the shrink is done. Typically runs faster than a normal shrink operation.

If, for whatever reason you stop the function before it completes, it can be restarted. The function will pick back up moving indexes as needed.

**IMPORTANT**: The second file that gets created will match the used size of the original filegroup. You must have enough disk space to support this.

## More Information     
Wrote this after I read this post by Paul Randal: <a href="https://www.sqlskills.com/blogs/paul/why-you-should-not-shrink-your-data-files/" target="_blank">Why you should not shrink your data files</a>  
    
I always knew shrinking was very bad, but until I read these comments by Paul my brain never clicked that there could be a better way:

QUOTE (Paul Randal):
    
>    The method I like to recommend is as follows:
>
> 1. Create a new filegroup
> 2. Move all affected tables and indexes into the new filegroup using the
> CREATE INDEX … WITH (<a href="https://learn.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql?view=sql-server-ver16#drop_existing---on--off-" target="_blank">DROP_EXISTING = ON</a>) syntax, to move the tables
> and remove fragmentation from them at the same time
> 3. Drop the old filegroup that you were going to shrink anyway (or
> shrink it way down if its the primary filegroup)
> 4. Move the indexes back to the original filegroup if desired (added by me :))

This script automates those steps so you don't have to.

## Syntax
    Invoke-DBSafeShrink 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [[-Credentials] <PSCredential>] 
        [[-FileGroupName] <String>] 
        [[-NewFileDirectory] <DirectoryInfo>] 
        [[-Direction] <String>] 
        [-AdjustRecovery ] 
        [[-ShrinkTimeout] <Int32>] 
        [[-ShrinkIncrementMB] <Int32>] 
        [[-IndexMoveTimeout] <Int32>] 
        [[-MinimumFreeSpaceMB] <Int32>] 
        [[-TlogBackupJobName] <String>] 
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
        The databases to shrink. A string array.

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

    -FileGroupName <String>
        The file group name to shrink. Defaults to PRIMARY. It does not matter 
        if there are multiple mdf or ldf files assigned.

        Required?                    false
        Position?                    4
        Default value                PRIMARY
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -NewFileDirectory <DirectoryInfo>
        If passed, then this will be the directory that the new temporary file will be 
        created in.
        
        Otherwise it will default to the same directory as the primary file. This directory 
        will be created if it does not exist. If it already exists, then nothing happens. 
        If the path is a local path, then the directory will be created on the server 
        using xp_create_subdir.
        
        NOTES:
            - The drive must exist, else an exception will occur
            - The SQL Server account must have write access to the target folder, 
            else an exception will occur

        Required?                    false
        Position?                    5
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Direction <String>
        If the direction is twoway then the the indexes are moved to the temporary file 
        and back after the orginal file is shrunk. If the direction is oneway, then the 
        indexes are moved to the temporary file, and the process will be complete.

        Required?                    false
        Position?                    6
        Default value                twoway
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -AdjustRecovery <SwitchParameter>
        If this switch is enabled then the recovery model of the database will be 
        temporarily changed to SIMPLE, then put back to the original recovery model. 
        If the switch is missing, then the recovery model will not be changed.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ShrinkTimeout <Int32>
        If the original requires shrinking in a twoway operation, then the shrinks 
        will occur in very small chunks at a time. This timeout will control how 
        long that operation can run before timing out.
        
        NOTES: This timeout is in minutes.

        Required?                    false
        Position?                    7
        Default value                10
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -ShrinkIncrementMB <Int32>
        The amount of MB to shrink the file each shrink attempt. If left as the 
        default of 0 then a simple formula will adjust the shrink increment based 
        upon the file size.

        Required?                    false
        Position?                    8
        Default value                0
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IndexMoveTimeout <Int32>
        The amount of time that controls how long a index move can run before 
        timing out.
        
        NOTES: This timeout is in minutes.

        Required?                    false
        Position?                    9
        Default value                5
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -MinimumFreeSpaceMB <Int32>
        The file shrunk must have at least this amount of free space, otherwise
        the shrink operation will write out a warning and skip the shrink operation 
        for this file. If there are multiple files in the filegroup, then the total 
        free space of the all the files must be greater than this value.

        Required?                    false
        Position?                    10
        Default value                250
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -TLogBackupJobName <String>
        The name of a TLOG back up job name. If passed in, then the job will be 
        temporarily disabled until the process finishes as TLOG backups will interfere 
        with the file operations. The job will be re-enabled once the process finishes.

        Required?                    false
        Position?                    11
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
 
[Back](/README.md)