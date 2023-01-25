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
            - Move the indexes back to the original filegroup if desired (added by me :))

        This script automates those steps so you don't have to.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Databases
        The databases to shrink. A string array.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER FileGroupName
        The file group name to shrink. Defaults to PRIMARY. It does not matter if there are
        multiple mdf or ldf files assigned.

    .PARAMETER NewFileDirectory
        If passed, then this will be the directory that the new temporary file will be created in.
        Otherwise it will default to the same directory as the primary file. This directory will
        be created if it does not exist. If it already exists, then nothing happens. If the path
        is a local path, then the directory will be created on the server using xp_create_sub directory.

        NOTES:
            - The drive must exist, else an exception will occur
            - The SQL Server account must have write access to the target folder, else an exception will occur

    .PARAMETER Direction
        If the direction is twoway then the the indexes are moved to the temporary file and back
        after the original file is shrunk. If the direction is oneway, then the indexes are moved
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

    .PARAMETER TLogBackupJobName
        The name of a TLOG back up job name. If passed in, then the job will be temporarily
        disabled until the process finishes as TLOG backups will interfere with the file operations.
         The job will be re-enabled once the process finishes.

    .INPUTS
        None. You cannot pipe objects to this script.

    .OUTPUTS
        Generates a table of records detailing before and after sizes for each filegroup shrunk.

    .EXAMPLE
        PS> Invoke-DBSafeShrink -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012"

    .EXAMPLE
        PS> Invoke-DBSafeShrink -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -MinimumFreeSpaceMB 1 -NewFileDirectory "D:\sqltemp\"

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [ValidateCount(1, 9999)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [string]$FileGroupName = "PRIMARY",
        [System.IO.DirectoryInfo]$NewFileDirectory,
        [ValidateSet("oneway", "twoway")]
        [string]$Direction = "twoway",
        [switch]$AdjustRecovery,
        [int]$ShrinkTimeout = 5,
        [ValidateRange(0, 20000)]
        [int]$ShrinkIncrementMB = 0,
        [int]$IndexMoveTimeout = 5,
        [int]$MinimumFreeSpaceMB = 250,
        [string]$TLogBackupJobName
    )

    begin {
        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstance -Credentials $Credentials
        $server = New-DBSMOServer -ServerInstance $ServerInstance -Credentials $Credentials

        # these two function can show you what fields are available
        # $server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Table], $true)
        # $server.GetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Table])
        # cut way down on the number of table fields smo pulls to hopefully speed it up
        [string[]]$fields = @("ID", "FileGroup", "HasClusteredIndex")
        $server.SetDefaultInitFields([Microsoft.SqlServer.Management.Smo.Table], $fields)

        $shrinkTimeOut = ([Timespan]::FromMinutes($ShrinkTimeout).TotalSeconds)
        $IndexMoveTimeout = ([Timespan]::FromMinutes($IndexMoveTimeout).TotalSeconds)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $swFormat = "hh\:mm\:ss"

        <#
        # IF THEY PASSED IN A NEW DIRECTORY, MAKE SURE IT IS CREATED
        #>
        if ($NewFileDirectory) {
            Write-Information "[$($sw.Elapsed.ToString($swFormat))] CREATING DIRECTORY ($($NewFileDirectory.FullName))"
            CreateNewDirectory -NewFileDirectory $NewFileDirectory -SqlCmdArguments $SqlCmdArguments
        }

        Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] STARTING" -ForegroundColor Yellow

        <#
        # IF THEY PASSED IN A TLOG BACKUP JOB NAME THEN STOP IT, AND WAIT A BIT FOR IT TO FINISH
        #>
        if ($TLogBackupJobName) {
            StopTLogBackupJob -SqlCmdArguments $SqlCmdArguments -TLogBackupJobName $TLogBackupJobName
        }

        $ret = @{}
        if ($AdjustRecovery.IsPresent) {
            $recoveryModels = AdjustRecoveryModels -AdjustRecovery $AdjustRecovery -SqlCmdArguments $SqlCmdArguments -Databases $Databases -recoveryModels @{} -TargetRecoveryModel "SIMPLE"
        }
    }

    process {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database]

            # try to enum the tables to hopefully speed this up
            $db.EnumObjects([Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Table) | Out-Null

            if ($db.Name -ne $Database) {
                Write-Warning "Can't find the database [$Database] in '$ServerInstance'"
                continue
            };

            $originalFG = $db.FileGroups | Where-Object { $_.Name -ieq $fileGroupName } | Select-Object -First 1
            if (-not $originalFG) {
                Write-Warning "Filegroup [$fileGroupName] not found in database: [$Database]"
                continue
            }

            $freeSpace = GetFreeSpace -SqlCmdArguments $SqlCmdArguments -Database $Database -FileGroupName $FileGroupName | Where-Object { $_.used_space_mb -gt 0 }
            $totals = $freeSpace | Measure-Object -Property free_space_mb, used_space_mb -Sum

            if ($totals[0].Sum -lt $MinimumFreeSpaceMB ) {
                Write-Warning "Database [$Database] does not have any files with the minimum required free space of $MinimumFreeSpaceMB MB for this operation to continue."
                continue
            }

            $usedTotalSize = $totals[1].Sum
            # in case of a restart, figure out the average without counting the shrink temp file in the divisor
            $averageUsedSize = $totals[1].Sum / ([System.Object[]]($freeSpace | Where-Object { $_.filegroup_name -ine "SHRINK_DATA_TEMP" })).Count

            foreach ($fs in $freeSpace) {
                $fileInfo = [PSCustomObject] @{
                    Database = $Database
                    FileGroupName = [string]$fs.filegroup_name
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

            $fi = [System.IO.FileInfo]$originalFile.FileName
            $newFileName = "$($fi.DirectoryName)\$($fi.BaseName)_SHRINK_DATA_TEMP$($fi.Extension)"

            if ($NewFileDirectory) {
                $newFileName = [System.IO.Path]::Combine($NewFileDirectory.FullName, ([System.IO.FileInfo]$newFileName).Name)
            }

            Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] SHRINKING SERVER: $ServerInstance, DATABASE: $Database, FILEGROUP: $fileGroupName" -ForegroundColor Cyan

            <#
            # SETUP THE NEW FILEGROUP AND FILE, BACKUP OPERATIONS CAN CONFLICT, ITS BEST TO STOP BACK JOBS AHEAD OF TIME
            #>
            AddTempFileGroupAndFile -SqlCmdArguments $SqlCmdArguments -NewFileName $newFileName -Size $usedTotalSize -OriginalFile $originalFile

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
                Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] SHRINKING FILES IN FG $fileGroupName" -ForegroundColor Magenta
                foreach($file in $originalFiles) {
                    # shrink each file a percentage at a time to keep from possibly timing out the shrink. cause even EMPTY files take a long time to shrink. WTF.
                    $fileName = $file.Name
                    [int]$size = $file.Size

                    Write-Verbose "LOOPING SHRINKFILE"
                    $size = ShrinkFile -SqlCmdArguments $SqlCmdArguments -size $size -fileName $fileName -targetSizeMB $averageUsedSize -timeout $ShrinkTimeout -ShrinkIncrementMB $ShrinkIncrementMB | Select-Object -Last 1
                }
                Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] FINISHED SHRINKING FILES IN FG $fileGroupName" -ForegroundColor Magenta

                MoveIndexes -db $db -fromFG "SHRINK_DATA_TEMP" -toFG $fileGroupName -indicator "<--" -timeout $IndexMoveTimeout -SqlCmdArguments $SqlCmdArguments

                RemoveTempFileGroupAndFile -SqlCmdArguments $SqlCmdArguments -shrinkTimeOut $shrinkTimeOut
            }

            <#
            # PERFORM ONE LAST TRUNCATEONLY SHRINK
            #>
            Write-Information "[$($sw.Elapsed.ToString($swFormat))] SHRINKING FILES IN FG [$fileGroupName] WITH TRUNCATEONLY"
            foreach($file in $originalFiles) {
                $fileName = $file.Name
                $sql = "DBCC SHRINKFILE($fileName, TRUNCATEONLY) WITH NO_INFOMSGS"
                Write-Verbose "$sql"
                Invoke-Sqlcmd @SqlCmdArguments -Query $sql -QueryTimeout $shrinkTimeOut | Format-Table
            }

            <#
            # RECORD THE CHANGES AFTER THE OPERATION HAS COMPLETED FOR THE FILES
            #>
            $freeSpace = GetFreeSpace -SqlCmdArguments $SqlCmdArguments -Database $Database -FileGroupName $FileGroupName
            $freeSpace | ForEach-Object {
                $obj = $ret["$Database-$($_.file_name)"]
                if ($obj) {
                    $obj.SizeAfter = [int]$_.current_size_mb
                    $obj.UsedAfter = [int]$_.used_space_mb
                    $obj.FreeAfter = [int]$_.free_space_mb
                }
            }
            Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] FINISHED SHRINKING SERVER: $ServerInstance, DATABASE: $Database, FILEGROUP: $fileGroupName" -ForegroundColor Cyan
        }
    }

    end {
        # don't pass the target recovery model in so that the function will reset the name tag to the original
        if ($AdjustRecovery.IsPresent) {
            AdjustRecoveryModels -AdjustRecovery $AdjustRecovery -SqlCmdArguments $SqlCmdArguments -Databases $Databases -recoveryModels $recoveryModels -TargetRecoveryModel $null | Out-Null
        }

        if ($TLogBackupJobName) {
            $sql = "EXEC msdb.dbo.sp_update_job @job_name = N'$TLogBackupJobName', @enabled = 1 ;"
            Write-Information "[$($sw.Elapsed.ToString($swFormat))] ENABLING JOB [$TLogBackupJobName]"
            Write-Verbose $sql
            Invoke-Sqlcmd @SqlCmdArguments -query $sql
        }

        Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] FINISHED" -ForegroundColor Yellow
        $sw.Stop()

        return $ret.Values
    }
}


