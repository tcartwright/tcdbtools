function Invoke-DBSafeShrink {
    <#
    .SYNOPSIS
        Shrinks a Sql Server mdf database file without fragmenting the indexes. 

    .DESCRIPTION
        Shrinks a Sql Server mdf database file without fragmenting the indexes. Can be 
        used to migrate indexes to a new filegroup, or just shrink and move the indexes 
        back to the original filegroup after the shrink is done. Typically runs faster than
        a normal shrink operation.

        IMPORTANT: The second file that gets created will match the used size of the original
        filegroup. You must have enough disk space to support this.

        Wrote this after I read this post by Paul Randal: 
            https://www.sqlskills.com/blogs/paul/why-you-should-not-shrink-your-data-files/
        
        I always knew shrinking was very bad, but until I read these comments by 
        Paul my brain never clicked that there could be a better way:
        
        QUOTE (Paul Randal):
            The method I like to recommend is as follows:

            - Create a new filegroup
            - Move all affected tables and indexes into the new filegroup using the 
                CREATE INDEX … WITH (DROP_EXISTING = ON) ON syntax, to move the tables 
                and remove fragmentation from them at the same time
            - Drop the old filegroup that you were going to shrink anyway (or 
                shrink it way down if its the primary filegroup)
        
        This script automates those steps so you don't have to.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Databases
        The databases to shrink. A string array. 

    .PARAMETER UserName
        The sql user to connect as. 
        
        NOTES: If UserName or Password are missing, then trusted connections will be used.

    .PARAMETER Password
        The password for the sql user.

        NOTES: If UserName or Password are missing, then trusted connections will be used.

    .PARAMETER FileGroupName
        The file group name to shrink. Defaults to PRIMARY. It does not matter if there are 
        multiple mdf or ldf files assigned.

    .PARAMETER NewFileDirectory
        If passed, then this will be the directory that the new temprory file will be created in.
        Otherwise it will default to the same directory as the primary file. This directory will 
        be created if it does not exist. If it already exists, then nothing happens. If the path 
        is a local path, then the directory will be created on the server using xp_create_subdir.

        NOTES:
            - The drive must exist, else an exception will occur
            - The SQL Server account must have write access to the target folder, else an exception will occur

    .PARAMETER Direction
        If the direction is twoway then the the indexes are moved to the temporary file and back 
        after the orginal file is shrunk. If the direction is oneway, then the indexes are moved 
        to the temporary file, and the process will be complete.

    .PARAMETER AdjustRecovery
        If this switch is enabled then the recovery model of the database will be temporarily changed 
        to SIMPLE, then put back to the original recovery model. If the switch is missing, then the 
        recovery model will not be changed.

    .PARAMETER ShrinkTimeout
        If the original requires shrinking in a twoway operation, then the shrinks will occur 
        in very small chunks at a time. This timeout will control how long that operation can 
        run before timing out.

        NOTES: This timeout is in minutes.

    .PARAMETER ShrinkIncrementMB
        The amount of MB to shrink the file each shrink attempt. If left as the default of 0 then
        a simple formula will adjust the shrink increment based upon the file size.

    .PARAMETER IndexMoveTimeout
        The amount of time that controls how long a index move can run before timing out.
        
        NOTES: This timeout is in minutes.

    .PARAMETER MinimumFreeSpaceMB
        The file shrunk must have at least this amount of free space, otherwise the shrink
        operation will write out a warning and skip the shrink operation for this file.

    .PARAMETER TlogBackupJobName
        The name of a TLOG back up job name. If passed in, then the job will be temporarily 
        disabled until the process finishes as TLOG backups will interfere with the file operations.

    .INPUTS
        None. You cannot pipe objects to this script.

    .OUTPUTS
        Generates a table of records detailing before and after sizes for each filegroup shrunk.

    .EXAMPLE
        PS> .\Invoke-DBSafeShrink -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" 

    .EXAMPLE
        PS> .\Invoke-DBSafeShrink -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -UserName "user.name" -Password "ilovelamp" 

    .EXAMPLE
        PS> .\Invoke-DBSafeShrink -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -MinimumFreeSpaceMB 1 -NewFileDirectory "D:\sqltemp\" 

    .LINK
        Links to further documentation.

    .NOTES
        Author: Tim Cartwright

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string[]]$Databases, 
        [string]$UserName, 
        [string]$Password, 
        [string]$FileGroupName = "PRIMARY",
        [System.IO.DirectoryInfo]$NewFileDirectory,
        [ValidateSet("oneway", "twoway")]
        [string]$Direction = "twoway",
        [switch]$AdjustRecovery,
        [int]$ShrinkTimeout = 10,
        [int]$ShrinkIncrementMB = 0,
        [int]$IndexMoveTimeout = 5,
        [int]$MinimumFreeSpaceMB = 250,
        [string]$TlogBackupJobName 
    )

    begin {
        $sqlCon = InitSqlConnection -ServerInstance $ServerInstance -UserName $UserName -Password $Password
        $SqlCmdArguments = $sqlCon.SqlCmdArguments
        $server = $sqlCon.server

        $shrinkTimeOut = ([Timespan]::FromMinutes($ShrinkTimeout).TotalSeconds)
        $IndexMoveTimeout = ([Timespan]::FromMinutes($IndexMoveTimeout).TotalSeconds)

        <#
        # IF THEY PASSED IN A NEW DIRECTORY, MAKE SURE IT IS CREATED
        #>
        if ($NewFileDirectory) {
            if (([Uri]$NewFileDirectory.FullName).IsUnc) {
                if (-not $NewFileDirectory.Exists) {
                    New-Item $NewFileDirectory.FullName -ItemType Directory -Force | Out-Null
                }
            } else {
                try {
                    # create the directory on the sql server if it does not exist. has no effect if the directory is already created. Throws an exception if the path is invalid, usually the directory
                    $sql = "EXECUTE master.dbo.xp_create_subdir '$($NewFileDirectory.FullName)'"
                    Write-Verbose $sql
                    Invoke-Sqlcmd @SqlCmdArguments -query $sql
                } catch {
                    throw 
                    exit 1
                }
            }
        }

        <#
        # IF THEY PASSED IN A TLOG BACKUP JOB NAME THEN STOP IT, AND WAIT A BIT FOR IT TO FINISH
        #>
        if ($TlogBackupJobName) {
            # lets disable the job. We must ensure to re-enable it at the end
            $sql = "EXEC msdb.dbo.sp_update_job  
                @job_name = N'$TlogBackupJobName',  
                @enabled = 0 ;" 
            Write-Verbose $sql
            Invoke-Sqlcmd @SqlCmdArguments -query $sql

            # now, lets wait a bit so that if the job is running we can let it finish up
            $sql = "DECLARE @sanityCounter INT = 0

                WHILE EXISTS (
	                SELECT [job].[name]
		                ,job.job_id
		                ,[job].[originating_server]
		                ,[activity].[run_requested_date]
		                ,DATEDIFF(SECOND, [activity].[run_requested_date], GETDATE()) AS elapsed
	                FROM msdb.dbo.sysjobs_view AS job
	                JOIN msdb.dbo.sysjobactivity AS activity ON job.job_id = activity.job_id
	                JOIN msdb.dbo.syssessions AS sess ON sess.session_id = activity.session_id
	                JOIN (
		                SELECT MAX(agent_start_date) AS max_agent_start_date
		                FROM msdb.dbo.syssessions
	                ) AS sess_max ON [sess].[agent_start_date] = [sess_max].[max_agent_start_date]
	                WHERE [activity].[run_requested_date] IS NOT NULL
		                AND [activity].[stop_execution_date] IS NULL
		                AND [job].[name] = '$TlogBackupJobName') BEGIN
		            
                    -- wait at max 2 minutes
	                SET @sanityCounter += 1
	                IF @sanityCounter > 24 BREAK
	                WAITFOR DELAY '00:00:05'
                END"
            Write-Verbose $sql
            Invoke-Sqlcmd @SqlCmdArguments -query $sql
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $swFormat = "hh\:mm\:ss"
        $ret = @{}
        Write-Host "[$($sw.Elapsed.ToString($swFormat))] STARTING" -ForegroundColor Yellow

        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database] 

            if ($db.Name -ne $Database) { 
                Write-Warning "Can't find the database [$Database] in '$ServerInstance'" 
                continue
            };
            <#
            # ADJUST THE RECOVERY IF REQUESTED, IF WE ARE ALREADY NOT IN SIMPLE
            #>
            if ($AdjustRecovery.IsPresent -and $originalRecovery -ine "Simple") {
                Write-Host "[$($sw.Elapsed.ToString($swFormat))] SETTING DATABASE RECOVERY TO SIMPLE" -ForegroundColor Yellow
                $sql = "ALTER DATABASE [$Database] SET RECOVERY SIMPLE"
                Write-Verbose $sql
                Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" 
            }
        }
    }

    process {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database] 

            if ($db.Name -ne $Database) { 
                Write-Warning "Can't find the database [$Database] in '$ServerInstance'" 
                continue
            };

            $originalFG = $db.FileGroups | Where-Object { $_.Name -ieq $fileGroupName } | Select-Object -First 1
            if (-not $originalFG) {
                Write-Warning "Filegroup [$fileGroupName] not found in database: [$Database]"
                continue
            }

            $freeSpace = GetFreeSpace -SqlCmdArguments $SqlCmdArguments -Database $Database
            foreach ($fs in $freeSpace) {
                $fileInfo = [PSCustomObject] @{
                    Database = $Database
                    FileName = [string]$fs.file_name
                    SizeBefore = [int]$fs.current_size_mb
                    UsedBefore = [int]$fs.used_space_mb
                    FreeBefore = [int]$fs.free_space_mb
                    SizeAfter  = [int]0
                    UsedAfter  = [int]0
                    FreeAfter  = [int]0
                }

                $ret.Add("$Database-$($fileInfo.FileName)", $fileInfo) | Out-Null
            }

            $originalFile = $originalFG.Files | Where-Object { $_.IsPrimaryFile } | Select-Object -First 1
            # capture this before moving any indexes as the values will be different after
            $originalFiles = $originalFG.Files | ForEach-Object { 
                [PSCustomObject] @{
                    Database = $Database
                    Name = [string]$_.Name
                    Size = $ret["$Database-$($_.Name)"].SizeBefore
                }
            }

            if (-not ($freeSpace | Where-Object { $_.free_space_mb -ge $MinimumFreeSpaceMB })) {  
                Write-Warning "Databasse [$Database] does not have any files with the minimum required free space of $MinimumFreeSpaceMB MB for this operation to continue."
                continue
            }
            $fi = [System.IO.FileInfo]$originalFile.FileName
            $newFileName = "$($fi.DirectoryName)\$($fi.BaseName)_SHRINK_DATA_TEMP$($fi.Extension)"
        
            if ($NewFileDirectory) {
                $newFileName = [System.IO.Path]::Combine($NewFileDirectory.FullName, ([System.IO.FileInfo]$newFileName).Name)
            }

            $totals = $freeSpace | Measure-Object -Property used_space_mb -Sum -Minimum
            $usedMinSize = $totals.Minimum
            $usedTotalSize = $totals.Sum
            $originalRecovery = $db.RecoveryModel 

            Write-Host "[$($sw.Elapsed.ToString($swFormat))] SHRINKING SERVER: $ServerInstance, DATABASE: $Database, FILEGROUP: $fileGroupName`r`n" -ForegroundColor Cyan

            <#
            # SETUP THE NEW FILEGROUP AND FILE, BACKUP OPERATIONS CAN CONFLICT, ITS BEST TO STOP BACK JOBS AHEAD OF TIME UNLESS IT ALREADY EXISTS
            #>
            Write-Host "[$($sw.Elapsed.ToString($swFormat))] CREATING FG SHRINK_DATA_TEMP" -ForegroundColor Yellow
            $sql = "
                IF NOT EXISTS (SELECT 1 FROM [$Database].sys.[filegroups] AS [f] WHERE [f].[name] = 'SHRINK_DATA_TEMP') BEGIN
                    ALTER DATABASE [$Database] ADD FILEGROUP SHRINK_DATA_TEMP
                END 
                IF NOT EXISTS (SELECT 1 FROM [$Database].sys.[database_files] AS [df] WHERE [df].[name] = 'SHRINK_DATA_TEMP') BEGIN
                    ALTER DATABASE [$Database]
                        ADD FILE (
                            NAME = 'SHRINK_DATA_TEMP',
                            FILENAME = '$newFileName',
                            SIZE = $($usedTotalSize)MB,
                            FILEGROWTH = $($originalFile.Growth)$($originalFile.GrowthType)
                        )
                    TO FILEGROUP SHRINK_DATA_TEMP
                END
                DBCC SHRINKFILE([SHRINK_DATA_TEMP], TRUNCATEONLY) WITH NO_INFOMSGS;
            "    
            try {
                PeformFileOperation -SqlCmdArguments $SqlCmdArguments -sql "$sql"
            } catch {
                Write-Warning $_.Exception.Message
                continue
            }

            <#
            # MOVE THE INDEXES FROM THE BASE FILEGROUP TO THE TARGET TEMP FILEGROUP
            #>
            MoveIndexes -db $db -fromFG $fileGroupName -toFG "SHRINK_DATA_TEMP" -indicator "-->" -timeout $IndexMoveTimeout -SqlCmdArguments $SqlCmdArguments

            <#
            # MOVE THE INDEXES BACK TO THE ORIGINAL FILEGROUP IF THE DIRECTION IS TWOWAY, AND REMOVE THE TEMP FILEGROUP AND FILE
            #>
            if ($direction -ieq "twoway") {
                <#
                # SHRINK THE OLD FILE GROUP DOWN A SMALL AMOUNT AT A TIME UNTIL WE REACH THE SMALLEST SIZE
                #>
                Write-Host "[$($sw.Elapsed.ToString($swFormat))] SHRINKING FILES IN FG $fileGroupName" -ForegroundColor Yellow
                foreach($file in $originalFiles) {
                    # shrink each file a percentage at a time to keep from possibly timing out the shrink. cause even EMPTY files take a long time to shrink. WTF.
                    $fileName = $file.Name
                    [int]$size = $file.Size 

                    Write-Verbose "LOOPING SHRINKFILE"
                    $size = ShrinkFile -SqlCmdArguments $SqlCmdArguments -size $size -fileName $fileName -targetSizeMB $usedMinSize -timeout $ShrinkTimeout -ShrinkIncrementMB $ShrinkIncrementMB | Select-Object -Last 1
                }

                MoveIndexes -db $db -fromFG "SHRINK_DATA_TEMP" -toFG $fileGroupName -indicator "<--" -timeout $IndexMoveTimeout -SqlCmdArguments $SqlCmdArguments

                # there have been occasions when an error occurred saying the file was not empty, until an empty file was issued. even though all of the indexes had been moved back
                $sql = "DBCC SHRINKFILE(SHRINK_DATA_TEMP, 'EMPTYFILE') WITH NO_INFOMSGS;"
                Write-Verbose $sql
                Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $shrinkTimeOut    

                Write-Host "[$($sw.Elapsed.ToString($swFormat))] REMOVING SHRINK_DATA_TEMP FG AND FILE" -ForegroundColor Yellow
                $sql = "
                    IF EXISTS (SELECT 1 FROM [$($SqlCmdArguments.Database)].sys.[database_files] AS [df] WHERE [df].[name] = 'SHRINK_DATA_TEMP') BEGIN
	                    ALTER DATABASE [$($SqlCmdArguments.Database)] REMOVE FILE [SHRINK_DATA_TEMP]
                    END

                    IF EXISTS (SELECT 1 FROM [$($SqlCmdArguments.Database)].sys.[filegroups] AS [f] WHERE [f].[name] = 'SHRINK_DATA_TEMP') BEGIN
	                    ALTER DATABASE [$($SqlCmdArguments.Database)] REMOVE FILEGROUP [SHRINK_DATA_TEMP]
                    END"
                PeformFileOperation -SqlCmdArguments $SqlCmdArguments -sql "$sql"            
            }

            <#
            # PERFORM ONE LAST TRUNCATEONLY SHRINK
            #>
            Write-Host "[$($sw.Elapsed.ToString($swFormat))] SHRINKING FILES IN FG [$fileGroupName] WITH TRUNCATEONLY" -ForegroundColor Yellow
            foreach($file in $originalFiles) {
                $fileName = $file.Name
                $sql = "DBCC SHRINKFILE($fileName, TRUNCATEONLY) WITH NO_INFOMSGS"
                Write-Verbose "$sql"
                Invoke-Sqlcmd @SqlCmdArguments -Query $sql -QueryTimeout $shrinkTimeOut | Format-Table
            }

            <#
            # RECORD THE CHANGES AFTER THE OPERATION HAS COMPLETED FOR THE FILES
            #>
            $freeSpace = GetFreeSpace -SqlCmdArguments $SqlCmdArguments -Database $Database
            $freeSpace | ForEach-Object { 
                $obj = $ret["$Database-$($_.file_name)"]
                if ($obj) {
                    $obj.SizeAfter = [int]$_.current_size_mb
                    $obj.UsedAfter = [int]$_.used_space_mb
                    $obj.FreeAfter = [int]$_.free_space_mb
                }
            }
            Write-Host "[$($sw.Elapsed.ToString($swFormat))] FISNISHED SHRINKING SERVER: $ServerInstance, DATABASE: $Database, FILEGROUP: $fileGroupName`r`n" -ForegroundColor Cyan
        }
    }

    end {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database] 

            if ($db.Name -ne $Database) { 
                Write-Warning "Can't find the database [$Database] in '$ServerInstance'" 
                continue
            };
            <#
            # SET THE RECOVERY BACK TO THE ORIGINAL RECOVERY IF REQUESTED AND THE ORIGINAL WAS NOT SIMPLE
            #>
            if ($AdjustRecovery.IsPresent -and $originalRecovery -ine "Simple") {
                Write-Host "[$($sw.Elapsed.ToString($swFormat))] RESETTING DATABASE RECOVERY MODE TO '$($originalRecovery.ToString().ToUpper())'" -ForegroundColor Yellow
                $sql = "ALTER DATABASE [$Database] SET RECOVERY $originalRecovery"
                Write-Verbose $sql
                Invoke-Sqlcmd @SqlCmdArguments -Query $sql -QueryTimeout $shrinkTimeOut 
            }
        }

        $sw.Stop()
        Write-Host "[$($sw.Elapsed.ToString($swFormat))] FINISHED" -ForegroundColor Yellow

        if ($TlogBackupJobName) {
            $sql = "EXEC msdb.dbo.sp_update_job  
                @job_name = N'$TlogBackupJobName',  
                @enabled = 1 ;" 
            Write-Verbose $sql
            Invoke-Sqlcmd @SqlCmdArguments -query $sql
        }

        return $ret.Values
    }
}


