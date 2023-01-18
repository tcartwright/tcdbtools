function Invoke-DBCompareServerSettings {
    <#
    .SYNOPSIS
        Compares all server settings for each instance passed in to generate a report showing differences. The user options are also compared
        individually. Any user option will have its name suffixed with (options).

    .DESCRIPTION
        Compares all server settings for each instance passed in to generate a report showing differences.

    .PARAMETER ServerInstances
        The sql server instances to connect to and compare. At least two servers must be passed in.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER IgnoreVersionDifferences
        If a SQL Server does not support a particular setting because it is an older version then the value will be a dash: "-". If this switch is
        present, then any setting value with a dash will not be considered a difference.

    .INPUTS
        None. You cannot pipe objects to this script.

    .OUTPUTS
        A list of the servers and a comparison report.

    .EXAMPLE
        PS> Invoke-DBCompareServerSettings -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -SourceFileGroupName SHRINK_DATA_TEMP -TargetFileGroupName PRIMARY

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateCount(2,999)]
        [string[]]$ServerInstances,
        [pscredential]$Credentials,
        [switch]$IgnoreVersionDifferences
    )

    begin {
        $groups = ($ServerInstances | Group-Object)
        if ($groups | Where-Object { $_.Count -gt 1 }) {
            throw "You cannot pass in duplicate ServerInstances"
            return
        }

        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstances[0] -Credentials $Credentials
        $list = [System.Collections.ArrayList]::new()

        $compareServers =  $ServerInstances | ForEach-Object { ($_).ToUpper() }
        $query = GetSQLFileContent -fileName "GetServerSettings.sql"
    }

    process {
        try {
            for ($i = 0; $i -le ($compareServers.Count - 1); $i++) {
                $srvrName = $compareServers[$i]
                $SqlCmdArguments.ServerInstance = $srvrName
                $results =  Invoke-SqlCmd @SqlCmdArguments -As DataRows -Query $query

                foreach ($r in $results) {
                    $setting = $list | Where-Object { $_.Name -ieq $r.Name }
                    if (-not $setting) {
                        # the original list does not have this setting yet, so add it
                        $setting = [PSCustomObject] @{
                            NAME = $r.Name
                            DIFFS = ""
                        }
                        $list.Add($setting) | Out-Null
                    }
                    $setting | Add-Member -MemberType NoteProperty -Name $srvrName -Value $r.Value
                }
            }
        } catch {
            throw
            return
        }

        # lets sort the list now that we have all the properties added
        $list = $list | Sort-Object { if ($_.Name -ieq "server version") { -1 } else { $_.Name } }

        # shorten the server versions to just the number
        $versions = $list | Where-Object { $_.Name -ieq "server version" }
        foreach ( $srvr in $compareServers ) {
            $version = $versions."$srvr"
            $version -imatch "Microsoft\s+SQL\s+Server\s+(\d{4})?\s+"
            $versions."$srvr" = $matches[1]
        }

        # add the missing settings for older servers that do not support some settings
        foreach ($item in $list) {
            foreach ( $srvr in $compareServers ) {
                if (-not (Get-Member -inputobject $item -name $srvr -Membertype Properties)) {
                    $item | Add-Member -MemberType NoteProperty -Name $srvr -Value "-"
                }
            }
        }

        # now that all the servers have values for each of the fields, lets compare all the values
        foreach ($result in $list) {
            $isDiff = CompareSettings -setting $result -propertyNames $compareServers -IgnoreVersionDifferences:$IgnoreVersionDifferences.IsPresent
            $result.DIFFS = $isDiff
        }
    }

    end {
        return $list
    }
}
