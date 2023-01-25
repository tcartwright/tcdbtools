function Test-DBReadOnlyRouting {
    <#
    .SYNOPSIS
        Tests read only routing for an availability group, and returns whether or not the routing is valid.

    .DESCRIPTION
        Tests read only routing for an availability group, and returns whether or not the routing is valid.

    .PARAMETER ServerInstances
        The sql server instances to connect to. This should be the listener name of the AG group.

    .PARAMETER Database
        The database. This database must be a synchronized database. If left empty, the the script will attempt to discover a synchronized database.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used. This authentication will
        be used for each server.

    .OUTPUTS

    .EXAMPLE
        PS >Test-DBReadOnlyRouting -ServerInstances "listener1", "listener2" | format-table

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
        [string]$Database,
        [pscredential]$Credentials
    )

    begin {
        $ret = New-Object 'System.Collections.Generic.List[System.Object]'
    }

    process {
        foreach ($ServerInstance in $ServerInstances) {
            try {
                $serverTest = [TestReadonlyRoutingResults]::new()
                $serverTest.ListenerName = $ServerInstance
                $serverTest.ReadOnlyIsValid = $false

                $ret.Add($serverTest) | Out-Null

                $connection = New-DBSQLConnection -ServerInstance $ServerInstance -Database "master" -Credentials $Credentials
                $connectionRO = New-DBSQLConnection -ServerInstance $ServerInstance -Database "master" -Credentials $Credentials -ApplicationIntent ReadOnly

                $connection.Open()

                if (-not $Database) {
                    $sql = (GetSQLFileContent -fileName "FindSynchronizedDB.sql") -f $Database
                    $Database = Invoke-DBScalarQuery -conn $connection -sql $sql
                } else {
                    # doing this to block sql injection for the USE statement below. ensure their db name actually exists and to also ensure it is synchronized
                    $sql = "SELECT d.[name] FROM sys.databases d WHERE d.[name] = @name"
                    $parameters = @(
                        (New-DBSqlParameter -name "@name" -type NVarChar -size 256 -value $Database)
                    )
                    $Database = Invoke-DBScalarQuery -conn $connection -sql $sql -parameters $parameters
                }

                if ($Database) {
                    $connectionRO.Open()
                    $query = "USE [$Database]; SELECT @@SERVERNAME;"

                    Write-Information "TESTING Read Only Routing for: `r`n`tSERVER: $($ServerInstance.ToUpper())`r`n`tDATABASE: $($Database.ToUpper())`r`n"
                    Write-Information "Connecting using RW connection"
                    $server = (Invoke-DBScalarQuery -conn $connection -sql $query)
                    Write-Information "Connecting using RO connection"
                    $serverRO = (Invoke-DBScalarQuery -conn $connectionRO -sql $query)

                    $serverTest.ReadOnlyServer = $serverRO
                    $serverTest.ReadWriteServer = $server
                    $serverTest.ReadOnlyIsValid = $serverRO -ine $server
                    $serverTest.Database = $Database
                    if (-not $serverTest.ReadOnlyIsValid) {
                        $serverTest.Reason = "SERVERS ARE EQUAL"
                    }
                } else {
                    $serverTest.Reason = "NO SYNCHRONIZED DBS"
                }
            } catch {
                $serverTest.Reason = "EXCEPTION: $($_.Exception.GetBaseException().Message)"
            } finally {
                if ($connection) { $connection.Dispose() }
                if ($connectionRO) { $connectionRO.Dispose() }
            }
        }
    }

    end {
        return $ret
    }
}
