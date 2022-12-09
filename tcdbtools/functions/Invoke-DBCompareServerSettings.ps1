function Invoke-DBCompareServerSettings {
    <#
        .SYNOPSIS
            Compares all server settings for each intstance passed in to generate a report showing differences.

        .DESCRIPTION
            Compares all server settings for each intstance passed in to generate a report showing differences.

        .PARAMETER ServerInstances
            The sql server instances to connect to and compare.

        .PARAMETER Credentials
            Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

        .INPUTS
            None. You cannot pipe objects to this script.

        .OUTPUTS
            A list of the servers and a comparison report.

        .EXAMPLE
            PS> .\Invoke-DBCompareServerSettings -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -SourceFileGroupName SHRINK_DATA_TEMP -TargetFileGroupName PRIMARY

        .EXAMPLE
            PS> .\Invoke-DBCompareServerSettings -ServerInstance "servername" -Databases "AdventureWorks2008","AdventureWorks2012" -UserName "user.name" -Password "ilovelamp" -SourceFileGroupName PRIMARY -TargetFileGroupName SHRINK_DATA_TEMP

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
        [pscredential]$Credentials
    )

    begin {
        $sqlCon = InitSqlConnection -ServerInstance $ServerInstances[0] -Credentials $Credentials
        $SqlCmdArguments = $sqlCon.SqlCmdArguments

        $compareServers =  $ServerInstances | ForEach-Object { ($_).ToUpper() }
        $query = "SELECT Name, Value FROM sys.configurations ORDER BY name"
    }

    process {
        try {
            $results =  Invoke-SqlCmd @SqlCmdArguments -As DataRows -Query $query -ConnectionTimeout 10 -ErrorAction Stop | `
                Select-Object -prop Name, `
                    @{ Name = "Diffs"; Expression = "-"}, `
                    @{ Name = "$($compareServers[0])"; Expression = { $_.Value }}


            for ($num = 1; $num -le ($ServerInstances.Count - 1); $num++) {
                $SqlCmdArguments.ServerInstance = $ServerInstances[$num]
                $results1 =  Invoke-SqlCmd @SqlCmdArguments -As DataRows -Query $query -ConnectionTimeout 10 -ErrorAction Stop
                $srvName = $compareServers[$num]

                foreach($result in $results) {
                    $setting = $results1 | Where-Object { $_.Name -ieq $result.Name }
                    if ( $setting ) { $value = $setting.Value } else { $value = "-" }
                    $result | Add-Member -MemberType NoteProperty -Name $srvName -Value $value
                }
            }
        } catch {
            throw
            return
        }

        foreach($result in $results) {
            $isDiff = CompareSettings -setting $result -propertyNames $compareServers
            $result.Diffs = $isDiff
        }

    }

    end {
        return $results
    }
}
