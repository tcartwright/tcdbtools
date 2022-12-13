function GetFreeSpace($SqlCmdArguments, $Database) {
    $sql = "
        SELECT DB_NAME() AS db_name,
	        df.[name] AS file_name,
	        fn.[size] AS current_size_mb,
	        fn.[space_used] AS used_space_mb,
	        fn.[size] - fn.[space_used] AS free_space_mb
        FROM [$Database].sys.database_files df
        CROSS APPLY (
	        SELECT CAST(CAST(FILEPROPERTY(df.name,'SpaceUsed') AS INT) / 128.0 AS INT) AS [space_used],
		        CAST(df.[size] / 128.0 AS INT) AS [size]

        ) fn
        WHERE [df].[type_desc] = 'ROWS';"

    Write-Verbose $sql
    return Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -OutputAs DataRows
}

function PeformFileOperation($SqlCmdArguments, $sql) {
    # A t-log backup could be occuring which would cause this script to break, so lets pause for a bit to try again, if we get that specific error
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

function MoveIndexes ($SqlCmdArguments, $db, $fromFG, $toFG, $indicator, $timeout) {
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

                    # set the new filegroup, and the dropexisting property so the script will generate properly
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


function ShrinkFile($SqlCmdArguments, [string] $fileName, [int]$size, [int]$targetSizeMB = 5, [int]$timeout, [int]$ShrinkIncrementMB = 0) {
    # shrink N-gb at a a time
    [int]$shrinkIncrement = $ShrinkIncrementMB

    if ($shrinkIncrement -lt 50 -or $shrinkIncrement -gt 10000) {
        switch ($size) {
            {$_ -le 10000 } {
                $shrinkIncrement = 1000 # < 10 gb
            }
            {$_ -gt 10000 -and $_ -le 100000 } {
                $shrinkIncrement = 2500 # 10 gb - 100 gb
            }
            {$_ -gt 100000 -and $_ -le 1000000 } {
                $shrinkIncrement = 5000 # 100 gb - 1 tb
            }
            {$_ -gt 1000000 } {
                $shrinkIncrement = 7500 # > 1 tb
            }
            default {
                $shrinkIncrement = 5000
            }
        }
    }

    # set our target size to 75% of the original, to reduce file growths needed. This size should be the smallest of the files if there were multiple
    $targetSize = [Math]::Max(1, $targetSizeMB * 0.75)
    $rawsql = "DBCC SHRINKFILE([$fileName], {0}) WITH NO_INFOMSGS;"

    if ($size -gt 50 -or $size -gt $targetSize) {
        if ($shrinkIncrement -gt 0) {
            for($x = $size; $x -gt $targetSize; $x -= $shrinkIncrement) {
                $size = $x
                $sql = $rawsql -f $x
                Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING: $sql"
                Write-Verbose $sql
                Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout
            }
        }
    }

    $sql = $rawsql -f $targetSize
    Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING FINAL SHRINK: $sql"
    Write-Verbose $sql
    Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $shrinkTimeOut
}
