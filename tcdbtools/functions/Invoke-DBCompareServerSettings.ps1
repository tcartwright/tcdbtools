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
        $query = "
    DECLARE @options TABLE ([name] nvarchar(35), [minimum] int, [maximum] int, [config_value] int, [run_value] int)
    DECLARE @optionsCheck TABLE([id] int NOT NULL IDENTITY, [setting_name] varchar(128))
    DECLARE @current_value INT;

    INSERT INTO @options ([name], [minimum], [maximum], [config_value], [run_value])
    EXEC sp_configure 'user_options';

    SELECT @current_value = [config_value] FROM @options;

    INSERT INTO @optionsCheck
        ([setting_name])
    VALUES
        ('DISABLE_DEF_CNST_CHK'),
        ('IMPLICIT_TRANSACTIONS'),
        ('CURSOR_CLOSE_ON_COMMIT'),
        ('ANSI_WARNINGS'),
        ('ANSI_PADDING'),
        ('ANSI_NULLS'),
        ('ARITHABORT'),
        ('ARITHIGNORE'),
        ('QUOTED_IDENTIFIER'),
        ('NOCOUNT'),
        ('ANSI_NULL_DFLT_ON'),
        ('ANSI_NULL_DFLT_OFF'),
        ('CONCAT_NULL_YIELDS_NULL'),
        ('NUMERIC_ROUNDABORT'),
        ('XACT_ABORT')

    ;WITH settings AS (
        SELECT
            [name], [value]
        FROM sys.configurations c
        ORDER BY [name]
        OFFSET 0 ROWS
    )

    SELECT *
    FROM [settings]
        UNION ALL
    SELECT CONCAT(oc.[setting_name], ' (options)'),
        [server_option] = CASE WHEN (@current_value & fn.[value]) = fn.[value] THEN 1 ELSE 0 END
    FROM @optionsCheck oc
    CROSS APPLY (
        SELECT [value] = CASE WHEN oc.id > 1 THEN POWER(2, oc.id - 1) ELSE 1 END
    ) fn
        "
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
