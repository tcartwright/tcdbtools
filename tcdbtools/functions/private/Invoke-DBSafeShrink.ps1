function GetFreeSpace {
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
        [string]$Database,
        [string]$FileGroupName
    )

    begin {
        $sql = (GetSQLFileContent -fileName "GetFreeSpace.sql") -f $Database
        [Microsoft.Data.SqlClient.SqlConnection]$connection = New-DBSQLConnection @SqlCmdArguments
    }
    process {
        $connection.Open()

        $params = @()
        $params += (New-DBSqlParameter -name "@FileGroupName" -type VarChar -size 1000 -value $FileGroupName)
        $dataset = Invoke-DBDataSetQuery -conn $connection -sql $sql -parameters $params

        return $dataset.Tables | Select-Object -First 1
    }

    end {
        if ($connection) { $connection.Dispose() }
    }
}

function PerformFileOperation {
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
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
            Invoke-Sqlcmd @SqlCmdArguments -Query $sql -Encrypt Optional
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

function ScriptIndex {
    param(
        $index,
        [string]$toFG,
        [bool]$Online
    )
    # set the new FileGroup, and the DropExistingIndex property so the script will generate properly
    $index.FileGroup = $toFG
    $index.DropExistingIndex = $true
    # not all indexes support online rebuilds, so we need to determine that before enabling it
    if ($index.IsOnlineRebuildSupported) {
        $index.OnlineIndexOperation = $Online
    }
    $sql = $index.Script()
    return $sql
}

function MoveIndexes {
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
        $db,
        [string]$fromFG,
        [string]$toFG,
        [string]$indicator,
        [int]$timeout,
        [switch]$Online,
        [string]$whereClause,
        [Microsoft.Data.SqlClient.SqlParameter[]]$parameters
    )
    # using sql to scan for the indexes to move instead of scanning SMO, as SMO is very, very slow scanning the tables
    # especially if some of the tables do not have indexes in the fromFG

    $sql = (GetSQLFileContent -fileName "GetIndexes.sql") -f ($db.Name), $fromFG
    $sql = $sql -ireplace "--<<extra_where>>", $whereClause
    # we will reflect into this object when moving lob data to get the string representation of a data type
    $method = [Microsoft.SqlServer.Management.Smo.UserDefinedDataType].GetMethod('GetTypeDefinitionScript', [Reflection.BindingFlags]::NonPublic -bor [Reflection.BindingFlags]::Static)
    $scriptMakerPreferences = ([Microsoft.SqlServer.Management.Smo.ScriptMaker]::new()).Preferences
    
    Write-Verbose $sql
    $connection = New-DBSqlConnection @SqlCmdArguments
    try {
        $connection.Open()
        $indexes = Invoke-DBDataTableQuery -conn $connection -Query $sql -timeout $timeout -parameters $parameters
    }
    finally {
        if ( $connection )  { $connection.Dispose() }
    }

    if ($Online.IsPresent -and $db.Parent.DatabaseEngineEdition -ine "Enterprise") {
        Write-Warning "Online operations can only be used from Enterprise edition"
        $Online = $false
    }

    $indexCounter = 0

    $indexList = $indexes | Where-Object { $_.index_type -imatch "CLUSTERED|NONCLUSTERED|HEAP" -and $_.alloc_unit_type -ieq "IN_ROW_DATA" }
    $indexCountTotal = 0
    if ($indexList) {
        if ($indexList -is [System.Data.DataRow]) {
            $indexCountTotal = 1
        } else {
            $indexCountTotal = $indexList.Count
        }
    }
    $activity = "MOVING ($indexCountTotal) INDEXES FROM FILEGROUP [$fromFG] TO FILEGROUP [$toFG] FOR DATABASE: [$($db.Name)]"
    Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] $activity" -ForegroundColor Green

    foreach ($tbl in ($indexList | Group-Object -Property schema_name,object_name)) {
        $table = $db.Tables.Item($tbl.Group[0].object_name, $tbl.Group[0].schema_name)
        $tableName = "[$($table.Schema)].[$($table.Name)]"

        Write-Information "[$($sw.Elapsed.ToString($swFormat))] `tTABLE: $tableName $indicator"

        # the table is a heap so we have to basically create a non-unique clustered index to move it..... then drop the index
        if (-not $table.HasClusteredIndex) {
            $guid = [Guid]::NewGuid().ToString("N")
            $indexName =  "PK_$guid"
            $columnName = "TempCol_$guid"
            $identityColumn = $table.Columns | Where-Object { $_.Identity }

            # if the table has an existing identity column add the clustered index to that, else we add an identity column
            if ($identityColumn) {
                $columnName = $identityColumn.Name

                # they have an existing identity, so lets use that to move to the new FG
                $sql = "CREATE CLUSTERED INDEX $indexName ON $tableName ($columnName) WITH (DATA_COMPRESSION = NONE) ON [$toFG];
                    DROP INDEX $indexName ON $tableName"
            } else {
                # add our own column to cover the chance that none of the columns are appropriate for a PK (bad design)
                $sql = "ALTER TABLE $tableName ADD [$columnName] BIGINT NOT NULL IDENTITY
                    CREATE CLUSTERED INDEX $indexName ON $tableName ($columnName) WITH (DATA_COMPRESSION = NONE) ON [$toFG];
                    DROP INDEX $indexName ON $tableName
                    ALTER TABLE $tableName DROP COLUMN [$columnName]"
            }

            Write-Verbose "$sql"
            Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout -Encrypt Optional
        }

        foreach ($index in $table.Indexes) {
            if ($index.FileGroup -ieq $fromFG -and $indexes.index_name -icontains $index.Name) {
                $indexCounter++

                Write-Progress -Activity $activity `
                    -Status “Moving index $indexCounter of $indexCountTotal [$($index.Name)] ” `
                    -PercentComplete (GetPercentComplete -counter $indexCounter -total $indexCountTotal)

                Write-Information "[$($sw.Elapsed.ToString($swFormat))] `t`tINDEX: [$($index.Name)] ($indexCounter of $indexCountTotal)"

                $MoveLobData = $index.IsClustered -and ($indexes | Where-Object { $_.index_name -ieq $index.Name -and $_.alloc_unit_type -ieq "LOB_DATA" })
                $sql = [System.Text.StringBuilder]::new()

                if ($MoveLobData) {
                    <#  http://sql10.blogspot.com/2013/07/easily-move-sql-tables-between.html

                        If the table contains LOB data which does not reside where the caller would like it to reside, then use the Brad Hoff's neat
                        partition scheme trick to move LOB data. Effectively, we simply create a partition function & scheme, rebuild the index on that
			            scheme, and then allow the normal rebuild (without partitioning) to be done afterwards.
                        For details, see Kimberly Tripp's site: http://www.sqlskills.com/blogs/kimberly/understanding-lob-data-20082008r2-2012/)
	                #>

                    $guid = [Guid]::NewGuid().ToString("N")
                    $firstColumn = $index.IndexedColumns | Select-Object -First 1
                    $methodParams = @($scriptMakerPreferences, $table.Columns[$firstColumn.Name], "DataType", $true)
                    $dataTypeString = $method.Invoke($null, $methodParams)

                    $sql.AppendLine("--LOB_DATA encountered. Creating partition to move LOB_DATA.")  | Out-Null
                    $sql.AppendLine("CREATE PARTITION FUNCTION PF_MOVE_HELPER_$guid ($dataTypeString) AS RANGE RIGHT FOR VALUES (0);") | Out-Null
                    $sql.AppendLine("CREATE PARTITION SCHEME PS_MOVE_HELPER_$guid AS PARTITION PF_MOVE_HELPER_$guid TO ([$toFG], [$toFG]);`r`n") | Out-Null

                    # use a temp name as the script engine mangles the partition schemes name when scripted out
                    $sqlScript = (ScriptIndex -index $index -toFG "REPLACE_ME_$guid" -Online $Online.IsPresent) -ireplace "ON\s+\[REPLACE_ME_$($guid)\]", "`r`nON PS_MOVE_HELPER_$guid([$($firstColumn.Name)]);"
                    $sql.AppendLine($sqlScript) | Out-Null
                    $sql.AppendLine("") | Out-Null
                }

                $sql.AppendLine((ScriptIndex -index $index -toFG $toFG -Online $Online.IsPresent)) | Out-Null

                if ($MoveLobData) {
                    $sql.AppendLine("`r`nDROP PARTITION SCHEME PS_MOVE_HELPER_$guid;") | Out-Null
                    $sql.AppendLine("DROP PARTITION FUNCTION PF_MOVE_HELPER_$guid;") | Out-Null
                }

                Write-Verbose "$($sql.ToString())"
                Invoke-Sqlcmd @SqlCmdArguments -Query "$($sql.ToString())" -QueryTimeout $timeout -Encrypt Optional
            }
        }
    }
    Write-Progress -Activity $activity -Completed
    Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] FINISHED $activity" -ForegroundColor Green
}


function ShrinkFile {
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
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

    Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] SHRINKING FILE $fileName FROM SIZE $size MB to $targetSize MB INCREMENTALLY BY $shrinkIncrement MB" -ForegroundColor Yellow
    Write-InformationColorized "[$($sw.Elapsed.ToString($swFormat))] ESTIMATED NUMBER OF SHRINKS: $loops" -ForegroundColor Yellow
    $rawsql = "DBCC SHRINKFILE([$fileName], {0}) WITH NO_INFOMSGS;"

    for($x = $size; $x -ge $targetSize; $x -= $shrinkIncrement) {
        $sql = $rawsql -f $x
        $counter++;
        Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING SHRINK ($counter of $loops) : $sql"
        Write-Verbose $sql
        Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout -Encrypt Optional
    }
    $size = $x + $shrinkIncrement

    if ($size -gt $targetSize) {
        $sql = $rawsql -f $targetSize
        Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING FINAL SHRINK: $sql"
        Write-Verbose $sql
        Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $shrinkTimeOut -Encrypt Optional
    }
}


function AdjustRecoveryModels {
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
        [string[]]$Databases,
        [System.Collections.HashTable]$recoveryModels,
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
            Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -Encrypt Optional
        }
    }
    return $recoveryModels
}

function StopTLogBackupJob {
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
        [string]$TLogBackupJobName
    )


    # lets disable the job. We must ensure to re-enable it at the end
    $sql = "EXEC msdb.dbo.sp_update_job @job_name = N'$TLogBackupJobName', @enabled = 0 ;"
    Write-Information "[$($sw.Elapsed.ToString($swFormat))] DISABLING JOB [$TLogBackupJobName]"
    Write-Verbose $sql
    Invoke-Sqlcmd @SqlCmdArguments -query $sql -Encrypt Optional

    # now, lets wait a bit so that if the job is running we can let it finish up
    $sql = (GetSQLFileContent -fileName "WaitForTsqlAgentJobToStop.sql"    ) -f $TLogBackupJobName
    Write-Verbose $sql
    Write-Information "[$($sw.Elapsed.ToString($swFormat))] WAITING FOR JOB [$TLogBackupJobName] TO STOP"
    Invoke-Sqlcmd @SqlCmdArguments -query $sql -Encrypt Optional
}

function RemoveTempFileGroupAndFile{
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
        [int]$shrinkTimeOut
    )
    # there have been occasions when an error occurred saying the file was not empty, until an empty file was issued. even though all of the indexes had been moved back
    $sql = "DBCC SHRINKFILE(SHRINK_DATA_TEMP, 'EMPTYFILE') WITH NO_INFOMSGS;"
    Write-Verbose $sql
    Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $shrinkTimeOut -Encrypt Optional

    Write-Information "[$($sw.Elapsed.ToString($swFormat))] REMOVING SHRINK_DATA_TEMP FG AND FILE"
    $sql = (GetSQLFileContent -fileName "RemoveShrinkTempObjects.sql") -f  ($SqlCmdArguments.Database)
    PerformFileOperation -SqlCmdArguments $SqlCmdArguments -sql "$sql"
}

function AddTempFileGroupAndFile {
    param (
        [System.Collections.HashTable]$SqlCmdArguments,
        $OriginalFile,
        $NewFileName,
        [int]$Size
    )

    Write-Information "[$($sw.Elapsed.ToString($swFormat))] CREATING FG SHRINK_DATA_TEMP"
    $sql = (GetSQLFileContent -fileName "AddShrinkTempObjects.sql") -f  $Database, $NewFileName, $Size, ($OriginalFile.Growth), ($OriginalFile.GrowthType)

    try {
        PerformFileOperation -SqlCmdArguments $SqlCmdArguments -sql "$sql"
    } catch {
        Write-Warning $_.Exception.Message
        continue
    }
}

function CreateNewDirectory {
    param (
        [System.IO.DirectoryInfo]$NewFileDirectory,
        [System.Collections.HashTable]$SqlCmdArguments
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
            Invoke-Sqlcmd @SqlCmdArguments -query $sql -Encrypt Optional
        } catch {
            throw
            exit 1
        }
    }
}