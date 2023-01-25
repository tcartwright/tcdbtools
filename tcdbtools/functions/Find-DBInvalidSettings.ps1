function Find-DBInvalidSettings {
    <#
    .SYNOPSIS
        Finds settings and options that may or may not be invalid depending upon design choices. They are typically
        invalid however and should be investigated.

    .DESCRIPTION
        Finds settings and options that may or may not be invalid depending upon design choices. They are typically
        invalid however and should be investigated. Any option marked with an X will typically have a non-standard
        setting, and or may not be an issue and should be investigated. This function does not fix any invalid
        settings. That is left to the DBA.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER CollationName
        The collation name you expect your server and databases to be using. Defaults to "SQL_Latin1_General_CP1_CI_AS"

    .PARAMETER Timeout
         The wait time (in seconds) before terminating the attempt to execute a command and generating an error. The default is 30 seconds.

    .OUTPUTS

    .EXAMPLE
        PS> $result = Find-DBInvalidSettings -ServerInstance "ServerName"

        PS> $result.ServerInstance
        PS> $result.ServerOptions    | Format-Table
        PS> $result.ServerSettings
        PS> $result.FileGrowths      | Format-Table
        PS> $result.DatabaseSettings | Format-Table
        PS> $result.DatabaseObjects  | Format-Table

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,
        [pscredential]$Credentials,
        [string]$CollationName = "SQL_Latin1_General_CP1_CI_AS",
        [int]$Timeout = 30
    )

    begin {
        $connection = New-DBSQLConnection -ServerInstance $ServerInstance -Database "master" -Credentials $Credentials

        $ret = [InvalidSettings]::new()
        $ret.ServerInstance = $ServerInstance
    }

    process {
        try {
            <#
            # FIND ALL THE POSSIBLE APPROPRIATE COLUMNS THAT COULD CONTAIN THE VALUE
            #>
            $connection.Open()
            $sql = (GetSQLFileContent -fileName "FindInvalidSettings.sql") -f $Database

            $parameters = @(
                (New-DBSqlParameter -name "desired_collation" -type VarChar -size 512 -value $CollationName)
            )

            $results = Invoke-DBDataSetQuery -conn $connection -sql $sql -parameters $parameters -timeout $Timeout
                        
            $ret.ServerOptions = DataTableToCustomObject -DataTable $results.Tables[1]
            $ret.ServerSettings = DataTableToCustomObject -DataTable $results.Tables[3]
            $ret.FileGrowths = DataTableToCustomObject -DataTable $results.Tables[5]
            $ret.DatabaseSettings = DataTableToCustomObject -DataTable $results.Tables[7]
            $ret.DatabaseObjects = DataTableToCustomObject -DataTable $results.Tables[9]
        } finally {
            if ($connection) { $connection.Dispose() }
        }
    }

    end {
        return $ret
    }
}
