function Invoke-DBScriptRunner {
    <#
    .SYNOPSIS
        Runs a query against one or more servers and databases. Captures the results and any messages.

    .DESCRIPTION
        Runs a query against one or more servers and databases. Captures the results and any messages.

    .PARAMETER Servers
        Collection of server / database names to run the query against.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER Query
        The query to run against each server / database combo.

    .PARAMETER MaxThreads
        The max number of threads to run the query with. Defaults to 8.

    .PARAMETER CommandTimeout
        The command timeout for the query in seconds.

    .OUTPUTS
        ServerInstance - The ServerInstance passed in.
        Database - The Database passed in.
        Results - The results of they query if there are any as a [System.Data.DataTable].
        Messages - the output of any PRINT statements used in the query.
        Success - True if the query succeeded, else false.
        Exception - A [System.Exception] if the query fails for any reason.

    .NOTES

    .EXAMPLE
        Runs the query against all of the server / databases specified.

        $servers = @()
        $servers += New-DBServer -ServerInstance "Server1" -Database "DbName1"
        $servers += New-DBServer -ServerInstance "Server1" -Database "DbName2"
        $servers += New-DBServer -ServerInstance "Server2" -Database "DbName1"
        $servers += New-DBServer -ServerInstance "Server2" -Database "DbName2"

        $query = "
            SET NOCOUNT ON
            PRINT CONCAT('HELLO WORLD: ', GETDATE())
            PRINT CONCAT('FROM USER: ', ORIGINAL_LOGIN())
            SELECT @@SERVERNAME AS [SERVERNAME],
                DB_NAME() AS [DB_NAME],
                @@VERSION AS [VERSION]
            "
        $results = Invoke-DBScriptRunner -Servers $servers -Query $query

        # the metadata return for each query invoked
        $results
        # output the total DataTable results of each query
        $results.Results | Format-Table

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateCount(1, 999)]
        [DBServer[]]$Servers,
        [pscredential]$Credentials,
        [string]$Query,
        [ValidateRange(1, 16)]
        [int]$MaxThreads = 8,
        [ValidateRange(1, 7200)]
        [int]$CommandTimeout = 30
    )

    begin {
        $ret = [System.Collections.ArrayList]::new()

        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
        # $RunspacePool.ThreadOptions = "ReuseThread"
        $RunspacePool.Open()

        $jobs = New-Object System.Collections.ArrayList
        $activity = "Running scripts"

        $counter = 1
        [int]$total = $Servers.Count
    }

    process {
        try {

            foreach ($server in $Servers) {

                # $QueryScriptRunnerBlock.Invoke($server, $Credentials, $query, $CommandTimeout)
                $jobName = "Running query on: $($server.ServerInstance) - $($server.database)"
                Write-Verbose "JOB $jobName SQL: `r`n$sql`r`n`r`n"

                Write-Progress -Activity $activity `
                    -Status $jobName `
                    -PercentComplete (GetPercentComplete -counter $counter -total $total)

                $PowerShell = [powershell]::Create()
                $PowerShell.RunspacePool = $RunspacePool
                $PowerShell.AddScript("Import-Module SqlServer") | Out-Null
                $PowerShell.AddScript(".\functions\ado\New-DBSqlConnection.ps1") | Out-Null
                $PowerShell.AddScript(".\functions\ado\Invoke-DBDataTableQuery.ps1") | Out-Null
                $PowerShell.AddScript($ScriptRunnerBlock) | Out-Null
                $PowerShell.AddArgument($server.ServerInstance) | Out-Null
                $PowerShell.AddArgument($server.Database) | Out-Null
                $PowerShell.AddArgument($Credentials) | Out-Null
                $PowerShell.AddArgument($query) | Out-Null
                $PowerShell.AddArgument($CommandTimeout) | Out-Null
                $Handle = $PowerShell.BeginInvoke()
                $temp = "" | Select-Object Name, PowerShell, Handle
                $temp.Name = $jobName
                $temp.PowerShell = $PowerShell
                $temp.Handle = $Handle
                $jobs.Add($temp) | Out-Null

                $counter++
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
                    -PercentComplete (GetPercentComplete -counter $counter -total $total)

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
                    $ret.Add($result) | Out-Null
                }
            }

            return $ret | Sort-Object -property @{ Expression={$_.ServerInstance} }, @{ Expression={$_.Database} }
        } finally {
            if ($connection) { $connection.Dispose() }
        }
    }

    end {
        if ($RunspacePool) { $RunspacePool.Dispose() }
    }
}

class DBServer {
    [String]$ServerInstance
    [String]$Database = "master"

    DBServer ([String]$ServerInstance, [String]$Database) {
        $this.ServerInstance = $ServerInstance
        $this.Database = $Database
    }
}

function New-DBServer() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Not needed')]
    param([String]$ServerInstance, [String]$Database = "master")
    return [DBServer]::new($ServerInstance, $Database)
}
