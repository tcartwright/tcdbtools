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
                Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING: $sql" -ForegroundColor Green
                Write-Verbose $sql
                Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $timeout
            }
        }
    }

    $sql = $rawsql -f $targetSize
    Write-Information "[$($sw.Elapsed.ToString($swFormat))] PERFORMING FINAL SHRINK: $sql" -ForegroundColor Green
    Write-Verbose $sql
    Invoke-Sqlcmd @SqlCmdArguments -Query "$sql" -QueryTimeout $shrinkTimeOut
}
