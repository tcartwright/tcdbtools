function Find-DBValue {
    <#
    .SYNOPSIS
        Scans a database for a value. Returns all tables and columns that contain that value, as well as the value itself.

    .DESCRIPTION
        Scans a database for a value. Returns all tables and columns that contain that value, as well as the value itself.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Database
        Specifies the name of the database.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER LookForValue
        The value to search for in the database. This string supports LIKE clause syntax.

    .PARAMETER LookForValueType
        The type of value being looked for. The valid values are "string" and "number". Use the appropriate one to scan the
        correct type of columns for the value you are looking for. Defaults to "string".

    .PARAMETER IncludeMaxWidthColumns
        Max width columns are not scanned by default unless this switch is enabled.

    .PARAMETER IncludeSchemas
        A list of schemas to include in the results. If not provided then all schemas will be returned.

    .PARAMETER ExcludeSchemas
        A list of schemas to exclude from the results.

    .PARAMETER IncludeTables
        A list of tables to include in the results. If not provided then all tables will be returned.

    .PARAMETER ExcludeTables
        A list of tables to exclude from the results.

    .PARAMETER MaxThreads
        The max number of threads to run sets of queries with. Defaults to 6.

    .OUTPUTS

    .NOTES
        More info on LIKE clause syntax: https://learn.microsoft.com/en-us/sql/t-sql/language-elements/like-transact-sql?view=sql-server-ver16#arguments

    .EXAMPLE
        Scans all string columns in all user defined tables in the dbo schema for the value "%tim%"
        PS> Find-DBValue -ServerInstance "ServerName" -Database "DBName" -LookForValue "%tim%" -IncludeSchemas @("dbo") | Format-Table

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database,
        [pscredential]$Credentials,
        [Parameter(Mandatory=$true)]
        [ValidateLength(2, 256)]
        [string]$LookForValue,
        [ValidateSet("number", "string")]
        [string]$LookForValueType = "string",
        [switch]$IncludeMaxWidthColumns,
        [string[]]$IncludeSchemas,
        [string[]]$ExcludeSchemas,
        [string[]]$IncludeTables,
        [string[]]$ExcludeTables,
        [ValidateRange(1, 16)]
        [int]$MaxThreads = 6
    )

    begin {
        $ret = @()
        #$ret = New-Object System.Collections.ArrayList

        $connection = New-DBSQLConnection -ServerInstance $ServerInstance -Database $Database -Credentials $Credentials -MultipleActiveResultSets
        $jobPrefix = "Scan For Value"

        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
        $RunspacePool.Open()
        # $Jobs = @()
        $jobs = New-Object System.Collections.ArrayList
    }

    process {
        try {
            <#
            # FIND ALL THE POSSIBLE APPROPRIATE COLUMNS THAT COULD CONTAIN THE VALUE
            #>
            $connection.Open()
            $sql = (GetSQLFileContent -fileName "ScanForValueColumns.sql")
            $where = ""
            $parameters = @(
                (New-DBSqlParameter -name "lookFor" -type VarChar -size 256 -value $LookForValue),
                (New-DBSqlParameter -name "lookForType" -type VarChar -size 10 -value $LookForValueType),
                (New-DBSqlParameter -name "includeMaxLengthColumns" -type Bit -value $IncludeMaxWidthColumns.IsPresent)
            )
            if ($IncludeSchemas) {
                $params = Get-DBInClauseParams -prefix "is" -values $IncludeSchemas -type NVarChar -size 256
                $where += "`r`n`tAND OBJECT_SCHEMA_NAME(t.object_id) IN ($(Get-DBInClauseString -parameters $params))"
                $parameters += $params
            }
            if ($ExcludeSchemas) {
                $params = Get-DBInClauseParams -prefix "es" -values $ExcludeSchemas -type NVarChar -size 256
                $where += "`r`n`tAND OBJECT_SCHEMA_NAME(t.object_id) NOT IN ($(Get-DBInClauseString -parameters $params))"
                $parameters += $params
            }
            if ($IncludeTables) {
                $params = Get-DBInClauseParams -prefix "it" -values $IncludeTables -type NVarChar -size 256
                $paramStr = Get-DBInClauseString -parameters $params -delimiter "), OBJECT_ID("
                $paramStr = "OBJECT_ID($($paramStr))"
                $where += "`r`n`tAND t.object_id IN ($paramStr)"
                $parameters += $params
            }
            if ($ExcludeTables) {
                $params = Get-DBInClauseParams -prefix "et" -values $ExcludeTables -type NVarChar -size 256
                $paramStr = Get-DBInClauseString -parameters $params -delimiter "), OBJECT_ID("
                $paramStr = "OBJECT_ID($($paramStr))"
                $where += "`r`n`tAND t.object_id NOT IN ($paramStr)"
                $parameters += $params
            }
            $sql = $sql -ireplace "--<<extra_where>>", $where
            Write-Verbose $sql
            $queryResults = Invoke-DBDataTableQuery -conn $connection -sql $sql -parameters $parameters

            <#
            # START THE JOBS USING CHUNKS OF THE RESULTS
            #>

            $skip = 0
            $take = 10
            $counter = 1
            [int]$total = $queryResults.Rows.Count / $take
            if ($queryResults.Rows.Count % $take -gt 0) { $total++ }
            $activity = "Starting $($total) jobs"

            $takeResults = $queryResults | Select-Object -Skip $skip -First $take

            while ($takeResults) {
                $sql = $takeResults.Query -join "`r`n"
                #  rip off the last union all
                $sql = "$($sql.SubString(0, $sql.Length - 10))"
                $parameters = @(
                    (New-DBSqlParameter -name "lookFor" -type VarChar -size 256 -value $LookForValue)
                )

                $jobName = "$jobPrefix - $counter"
                Write-Verbose "JOB $jobName SQL: `r`n$sql`r`n`r`n"

                Write-Progress -Activity $activity `
                    -Status “Starting Job $jobName of $total” `
                    -PercentComplete (([decimal][Math]::Min($total, $counter) / [decimal]$total) * 100.00)

                $PowerShell = [powershell]::Create()
                $PowerShell.RunspacePool = $RunspacePool
                $PowerShell.AddScript($QueryTableScriptBlock).AddArgument($connection).AddArgument($sql).AddArgument($parameters) | Out-Null
                $Handle = $PowerShell.BeginInvoke()
                $temp = "" | Select-Object Name, PowerShell, Handle
                $temp.Name = $jobName
                $temp.PowerShell = $PowerShell
                $temp.Handle = $Handle
                $jobs.Add($temp) | Out-Null

                $counter++

                $skip += $take
                $takeResults = $queryResults | Select-Object -Skip $skip -First $take
            }

            Write-Progress -Activity $activity -Completed

            <#
            # START SCANNING THE JOBS WAITING FOR THEM TO FINISH
            #>

            $counter = 0
            $activity = "Waiting for $($total) jobs to finish"

            while ($Jobs.Handle.IsCompleted -contains $false) {
                $counter = ($Jobs | Where-Object { $_.Handle.IsCompleted }).Count

                Write-Progress -Activity $activity `
                    -Status “Job(s) $counter of $total done” `
                    -PercentComplete (([decimal][Math]::Min($total, $counter) / [decimal]$total) * 100.00)

                Start-Sleep -Milliseconds 500
            }

            Write-Progress -Activity $activity -Completed

            <#
            # NOW GATHER THE RESULTS OF THE JOBS
            #>

            foreach($job in $jobs) {
                $result = $job.Powershell.EndInvoke($job.Handle)
                $job.Powershell.Dispose()

                if ($result) {
                    $ret += $result
                }
            }

            return $ret |
                Sort-Object server_name, db_name, schema_name, table_name, column_name |
                Select-Object db_name, schema_name, table_name, column_name, where_clause, value
        } finally {
            if ($connection) { $connection.Dispose() }
        }
    }

    end {
        if ($RunspacePool) { $RunspacePool.Dispose() }
    }
}
