function Test-DBSqlConnection {
    <#
    .SYNOPSIS
        Tests connectivity to a sql server, and returns information about the server if successful.

    .DESCRIPTION
        Tests connectivity to a sql server, and returns information about the server if successful.

    .PARAMETER ServerInstances
        The sql server instances to connect to. This should be the listener name of the AG group.

    .PARAMETER Database
        The database. This database must be a synchronized database. If left empty, the the script will attempt to discover a synchronized database.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used. This authentication will
        be used for each server.

    .PARAMETER ConnectionTimeout
        The time in seconds to wait for a successful connection to each server. Defaults to 10.

    .PARAMETER QueryTimeout
        The time in seconds to wait for the query to return results. Defaults to 5.

    .OUTPUTS

    .EXAMPLE
        PS >Test-DBSqlConnection -ServerInstances "listener1", "listener2" | format-table

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [OutputType([System.Collections.Generic.List[System.Object]])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateCount(1, 9999)]
        [string[]]$ServerInstances,
        [string]$Database = "master",
        [pscredential]$Credentials,
        [ValidateRange(2, 120)]
        [int]$ConnectionTimeout = 10,
        [ValidateRange(2, 120)]
        [int]$QueryTimeout = 5
    )

    begin {
        $ret = New-Object 'System.Collections.Generic.List[System.Object]'
    }

    process {
        foreach ($ServerInstance in $ServerInstances) {
            try {
                $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstance -Credentials $Credentials -Database $Database
                $serverTest = [TestSqlConnectionResults]::new()
                $serverTest.ServerInstance = $ServerInstance
                $serverTest.Database = $Database
                $serverTest.Success = $false

                $ret.Add($serverTest) | Out-Null

                $results = Invoke-Sqlcmd @SqlCmdArguments `
                    -Query "SELECT @@SERVERNAME AS [ServerName], @@VERSION AS [Version], GETDATE() AS [DateTime]" `
                    -QueryTimeout $QueryTimeout `
                    -ErrorAction Stop `
                    -Encrypt Optional `
                    -ConnectionTimeout $ConnectionTimeout

                if ($results) {
                    $serverTest.ServerName = $results.ServerName
                    $serverTest.Version = $results.Version
                    $serverTest.DateTime = $results.DateTime
                    $serverTest.Success = $true
                }

            } catch {
                $serverTest.Error = "EXCEPTION: $($_.Exception.GetBaseException().Message)"
            }
        }
    }

    end {
        return $ret
    }
}
