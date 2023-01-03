function GetFreeSpace {
    Param (
        [System.Collections.Hashtable]$SqlCmdArguments,
        [string]$Database,
        [string]$FileGroupName
    )

    $sql = "
        SELECT DB_NAME() AS [db_name],
            f.[name] AS [filegroup_name],
            df.[name] AS [file_name],
            fn.[size] AS current_size_mb,
            fn.[space_used] AS used_space_mb,
            fn.[size] - fn.[space_used] AS free_space_mb
        FROM [$Database].sys.database_files df
        INNER JOIN [$Database].sys.[filegroups] AS [f]
            ON [f].[data_space_id] = [df].[data_space_id]
        CROSS APPLY (
            SELECT CAST(CAST(FILEPROPERTY(df.name,'SpaceUsed') AS INT) / 128.0 AS INT) AS [space_used],
                CAST(df.[size] / 128.0 AS INT) AS [size]

        ) fn
        WHERE [df].[type_desc] = 'ROWS'
            AND [f].[name] IN (@FileGroupName, 'SHRINK_DATA_TEMP');
    "
    [System.Data.SqlClient.SqlConnection]$connection = New-DBSQLConnection @SqlCmdArguments
    try {
        $connection.Open()
        [System.Data.SqlClient.SqlCommand]$command = $connection.CreateCommand();
        $command.CommandText = $sql
        $command.CommandType = "Text"

        [System.Data.SqlClient.SqlParameter]$param = $command.CreateParameter()
		$param.ParameterName = "@FileGroupName";
		$param.SqlDBtype = [System.Data.SqlDbType]::VarChar;
        $param.Size = 1000
		$param.Direction = [System.Data.ParameterDirection]::Input;
		$param.value = $FileGroupName;

        Write-Verbose $sql
        $command.Parameters.Add($param)
		$dr = $command.ExecuteReader();

		[System.Data.DataTable]$dt = New-Object System.Data.DataTable;
		$dt.load($dr) | Out-Null;
    } finally {
        if ($dr) { $dr.Dispose() }
        if ($command) { $command.Dispose() }
        if ($connection) { $connection.Dispose() }
    }
    return $dt
}

function PerformFileOperation {
    Param (
        [System.Collections.Hashtable]$SqlCmdArguments,
        [string]$sql
    )
    # A t-log backup could be occurring which would cause this script to break, so lets pause for a bit to try again, if we get that specific error
    # https://blog.sqlauthority.com/2014/11/09/sql-server-fix-error-msg-3023-level-16-state-2-backup-file-manipulation-operations-such-as-alter-database-add-file-and-encryption-changes-on-a-database-must-be-serialized/
    $tryAgain = $false
    $tryAgainCount = 0
    $sleep = 15
    [int]$tryAgainCountMax = (300 / $sleep) # 300 (seconds) == 5 minutes wait, unless it succeeds

    do {
        $tryAgain = $false
        try {
            Write-Verbose "$sql"
            Invoke-Sqlcmd @SqlCmdArguments -Query $sql -ErrorAction Stop
        } catch {
            $msg = $_.Exception.GetBaseException().Message
            if (++$tryAgainCount -lt $tryAgainCountMax -and $msg -imatch "Backup,\s+file\s+manipulation\s+operations\s+\(such\s+as .*?\)\s+and\s+encryption\s+changes\s+on\s+a\s+database\s+must\s+be\s+serialized\.") {
                Write-Warning "BACKUP SERIALIZATION ERROR, PAUSING FOR ($sleep) SECONDS, AND TRYING AGAIN. TRY: $($tryAgainCount + 1)"
                $tryAgain = $true
                Start-Sleep -Seconds $sleep
            } else {
                # not the exception about a backup blocking us, or we are out of retries, so bail
                throw
            }
        }
    } while ($tryAgain)
}

function MoveIndexes {
    Param (
        [System.Collections.Hashtable]$SqlCmdArguments,
        $db,
        [string]$fromFG,
        [string]$toFG,
        [string]$indicator,
        [int]$timeout
    )
    # using sql to scan for the indexes to move instead of scanning SMO, as SMO is very, very slow scanning the tables
    # especially if some of the tables do not have indexes in the fromFG

    $sql = "
        SELECT OBJECT_SCHEMA_NAME(i.[object_id]) AS [schema_name],
	        OBJECT_NAME(i.[object_id]) AS [object_name]
            ,i.[index_id]
            ,i.[name] AS [index_name]
            ,i.[type_desc] AS [index_type]
        FROM [$($db.Name)].[sys].[indexes] i
        INNER JOIN [$($db.Name)].[sys].[filegroups] f
            ON f.[data_space_id] = i.[data_space_id]
        WHERE OBJECTPROPERTY(i.[object_id], 'IsUserTable') = 1
	        AND [f].[name] = '$fromFG'
        ORDER BY OBJECT_NAME(i.[object_id])
            ,i.[index_id]"
    Write-Verbose $sql
    $indexes = Invoke-Sqlcmd @SqlCmdArguments -Query $sql -QueryTimeout $timeout

    $indexCounter = 0
    $indexCountTotal = $indexes.Count
    $activity = "MOVING ($indexCountTotal) INDEXES FROM FILEGROUP [$fromFG] TO FILEGROUP [$toFG] FOR DATABASE: [$($db.Name)]"
    Write-InformationColored "[$($sw.Elapsed.ToString($swFormat))] $activity" -ForegroundColor Green

    foreach ($tbl in ($indexes | Group-Object -Property schema_name,object_name)) {
        $table = $db.Tables.Item($tbl.Group[0].object_name, $tbl.Group[0].schema_name)
        $tableName = "[$($table.Schema)].[$($table.Name)]"

        Write-Information "[$($sw.Elapsed.ToString($swFormat))] `tTABLE: $tableName $indicator"

        # the table is a heap so we have to basically create a non-unique clustered index to move it..... then drop the index
        if (-not $table.HasClusteredIndex) {
            $firstColumn = $table.Columns | Select-Object -First 1
            $indexName =  "PK_$([Guid]::NewGuid().ToString("N"))"
            $sql = "CREATE CLUSTERED INDEX $indexName ON $tableName ($($firstColumn.Name)) WITH (DATA_COMPRESSION = PAGE) ON [$toFG];
                DROP INDEX $indexName ON $tableName"

            Write-Verbose "$sql"
            Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout
        }

        foreach ($index in $table.Indexes) {
            if ($index.FileGroup -ieq $fromFG) {
                $indexCounter++

                Write-Progress -Activity $activity `
                    -Status “Moving index $indexCounter of $indexCountTotal [$($index.Name)] ” `
                    -PercentComplete (([decimal]$indexCounter / [decimal]$indexCountTotal) * 100.00)

                Write-Information "[$($sw.Elapsed.ToString($swFormat))] `t`tINDEX: [$($index.Name)] ($indexCounter of $indexCountTotal)"

                # set the new FileGroup, and the DropExistingIndex property so the script will generate properly
                $index.FileGroup = $toFG
                $index.DropExistingIndex = $true
                $sql = $index.Script()
                Write-Verbose "$sql"
                Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout
            }
        }
    }
    Write-Progress -Activity $activity -Completed
    Write-InformationColored "[$($sw.Elapsed.ToString($swFormat))] FINISHED $activity" -ForegroundColor Green
}


function ShrinkFile {
    Param (
        [System.Collections.Hashtable]$SqlCmdArguments,
        [string] $fileName,
        [int]$size,
        [int]$targetSizeMB = 5,
        [int]$timeout,
        [int]$ShrinkIncrementMB = 0
    )
    # shrink N-gb at a a time
    [int]$shrinkIncrement = $ShrinkIncrementMB

    if ($shrinkIncrement -lt 50 -or $shrinkIncrement -gt 10000) {
        $factor = 0.33

        switch ($size) {
            {$_ -le 50000 } {
                $factor = $factor * [Math]::Pow($factor, 1)
            }
            {$_ -gt 50000 -and $_ -le 500000 } {
                $factor = $factor * [Math]::Pow($factor, 2)
            }
            {$_ -gt 500000 -and $_ -le 5000000 } {
                $factor = $factor * [Math]::Pow($factor, 3)
            }
            {$_ -gt 5000000 -and $_ -le 50000000 } {
                $factor = $factor * [Math]::Pow($factor, 4)
            }
            default {
                $factor = $factor * [Math]::Pow($factor, 5)
            }
        }

        $shrinkIncrement = [int]($size * $factor)
        Write-Verbose "Shrink increment is: $shrinkIncrement MB"
    }

    # set our target size to % of the original, to reduce file growths needed.
    $targetSize = [Math]::Max(5, $targetSizeMB * 0.75)
    [int]$loops = (($size - $targetSize) / $shrinkIncrement) + 1
    $counter = 0

    Write-InformationColored "[$($sw.Elapsed.ToString($swFormat))] SHRINKING FILE $fileName FROM SIZE $size MB to $targetSize MB INCREMENTALLY BY $shrinkIncrement MB" -ForegroundColor Yellow
    Write-InformationColored "[$($sw.Elapsed.ToString($swFormat))] ESTIMATED NUMBER OF SHRINKS: $loops" -ForegroundColor Yellow
    $rawsql = "DBCC SHRINKFILE([$fileName], {0}) WITH NO_INFOMSGS;"

    for($x = $size; $x -ge $targetSize; $x -= $shrinkIncrement) {
        $sql = $rawsql -f $x
        $counter++;
        Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING SHRINK ($counter of $loops) : $sql"
        Write-Verbose $sql
        Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout
    }
    $size = $x + $shrinkIncrement

    if ($size -gt $targetSize) {
        $sql = $rawsql -f $targetSize
        Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING FINAL SHRINK: $sql"
        Write-Verbose $sql
        Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $shrinkTimeOut
    }
}


function AdjustRecoveryModels {
    Param(
        [System.Collections.Hashtable]$SqlCmdArguments,
        [string[]]$Databases,
        [System.Collections.Hashtable]$recoveryModels,
        [string]$TargetRecoveryModel
    )

    foreach($Database in $Databases) {
        $SqlCmdArguments.Database = $Database
        $db = $server.Databases[$Database]

        if ($db.Name -ne $Database) {
            Write-Warning "Can't find the database [$Database] in '$($SqlCmdArguments.ServerInstance)'"
            continue
        };
        # record the models the first time around, so that we can reset them when everything is done
        if (-not ($recoveryModels.ContainsKey($Database))) {
            $model = $db.RecoveryModel -replace "BulkLogged", "BULK_LOGGED"
            $recoveryModels.Add($Database, $model)
        }
        <#
        # ADJUST THE RECOVERY IF REQUESTED, IF WE ARE ALREADY NOT IN SIMPLE
        #>
        if ( $recoveryModels[$Database] -ine "SIMPLE" ) {
            if (-not $TargetRecoveryModel) {
                $TargetRecoveryModel = $recoveryModels[$Database]
            }

            Write-Information "[$($sw.Elapsed.ToString($swFormat))] SETTING RECOVERY FOR DATABASE [$Database] TO $TargetRecoveryModel"
            $sql = "ALTER DATABASE [$Database] SET RECOVERY $TargetRecoveryModel"
            Write-Verbose $sql
            Invoke-Sqlcmd @SqlCmdArguments -Query "$sql"
        }
    }
    return $recoveryModels
}

function StopTLogBackupJob {
    Param(
        [System.Collections.Hashtable]$SqlCmdArguments,
        [string]$TLogBackupJobName
    )


    # lets disable the job. We must ensure to re-enable it at the end
    $sql = "EXEC msdb.dbo.sp_update_job @job_name = N'$TLogBackupJobName', @enabled = 0 ;"
    Write-Information "[$($sw.Elapsed.ToString($swFormat))] DISABLING JOB [$TLogBackupJobName]"
    Write-Verbose $sql
    Invoke-Sqlcmd @SqlCmdArguments -query $sql

    # now, lets wait a bit so that if the job is running we can let it finish up
    $sql = "
    DECLARE @sanityCounter INT = 1

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
		    AND [job].[name] = '$TLogBackupJobName') BEGIN

	    RAISERROR('WAITING LOOP %d FOR JOB [%s] TO STOP', 0, 1, @sanityCounter, '$TLogBackupJobName') WITH NOWAIT
        -- wait at max 2 minutes
	    SET @sanityCounter += 1
	    IF @sanityCounter > 24 BEGIN
		    RAISERROR('SANITY LOOP COUNTER EXCEEDED WAITING FOR JOB [%s] TO STOP, EXITING.', 0, 1, '$TLogBackupJobName') WITH NOWAIT
		    BREAK
	    END
	    WAITFOR DELAY '00:00:05'
    END
    "
    Write-Verbose $sql
    Write-Information "[$($sw.Elapsed.ToString($swFormat))] WAITING FOR JOB [$TLogBackupJobName] TO STOP"
    Invoke-Sqlcmd @SqlCmdArguments -query $sql
}

function RemoveTempFileGroupAndFile{
    Param(
        [System.Collections.Hashtable]$SqlCmdArguments,
        [int]$shrinkTimeOut
    )
    # there have been occasions when an error occurred saying the file was not empty, until an empty file was issued. even though all of the indexes had been moved back
    $sql = "DBCC SHRINKFILE(SHRINK_DATA_TEMP, 'EMPTYFILE') WITH NO_INFOMSGS;"
    Write-Verbose $sql
    Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $shrinkTimeOut

    Write-Information "[$($sw.Elapsed.ToString($swFormat))] REMOVING SHRINK_DATA_TEMP FG AND FILE"
    $sql = "
        IF EXISTS (SELECT 1 FROM [$($SqlCmdArguments.Database)].sys.[database_files] AS [df] WHERE [df].[name] = 'SHRINK_DATA_TEMP') BEGIN
	        ALTER DATABASE [$($SqlCmdArguments.Database)] REMOVE FILE [SHRINK_DATA_TEMP]
        END

        IF EXISTS (SELECT 1 FROM [$($SqlCmdArguments.Database)].sys.[filegroups] AS [f] WHERE [f].[name] = 'SHRINK_DATA_TEMP') BEGIN
	        ALTER DATABASE [$($SqlCmdArguments.Database)] REMOVE FILEGROUP [SHRINK_DATA_TEMP]
        END"
    PerformFileOperation -SqlCmdArguments $SqlCmdArguments -sql "$sql"
}

function AddTempFileGroupAndFile {
    Param(
        [System.Collections.Hashtable]$SqlCmdArguments,
        $OriginalFile,
        $NewFileName,
        [int]$Size
    )

    Write-Information "[$($sw.Elapsed.ToString($swFormat))] CREATING FG SHRINK_DATA_TEMP"
    $sql = "
        IF NOT EXISTS (SELECT 1 FROM [$Database].sys.[filegroups] AS [f] WHERE [f].[name] = 'SHRINK_DATA_TEMP') BEGIN
            ALTER DATABASE [$Database] ADD FILEGROUP SHRINK_DATA_TEMP
        END
        IF NOT EXISTS (SELECT 1 FROM [$Database].sys.[database_files] AS [df] WHERE [df].[name] = 'SHRINK_DATA_TEMP') BEGIN
            ALTER DATABASE [$Database]
                ADD FILE (
                    NAME = 'SHRINK_DATA_TEMP',
                    FILENAME = '$NewFileName',
                    SIZE = $($Size)MB,
                    FILEGROWTH = $($OriginalFile.Growth)$($OriginalFile.GrowthType)
                )
            TO FILEGROUP SHRINK_DATA_TEMP
        END
        DBCC SHRINKFILE([SHRINK_DATA_TEMP], TRUNCATEONLY) WITH NO_INFOMSGS;
    "
    try {
        PerformFileOperation -SqlCmdArguments $SqlCmdArguments -sql "$sql"
    } catch {
        Write-Warning $_.Exception.Message
        continue
    }
}

function CreateNewDirectory {
    Param (
        [System.IO.DirectoryInfo]$NewFileDirectory,
        [System.Collections.Hashtable]$SqlCmdArguments
    )
    if (([Uri]$NewFileDirectory.FullName).IsUnc) {
        if (-not $NewFileDirectory.Exists) {
            New-Item $NewFileDirectory.FullName -ItemType Directory -Force | Out-Null
        }
    } else {
        try {
            # create the directory on the sql server if it does not exist. has no effect if the directory is already created. Throws an exception if the path is invalid, usually the drive
            $sql = "EXECUTE master.dbo.xp_create_subdir '$($NewFileDirectory.FullName)'"
            Write-Verbose $sql
            Invoke-Sqlcmd @SqlCmdArguments -query $sql
        } catch {
            throw
            exit 1
        }
    }
}