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

    #>
    Param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [pscredential]$Credentials
    )

    begin {
        $sqlCon = New-DBSqlObjects -ServerInstance $ServerInstance -Credentials $Credentials
        $SqlCmdArguments = $sqlCon.SqlCmdArguments
                
        $ret = [PSCustomObject] @{
            ServerInstance = $ServerInstance
            ServerOptions = $null
            ServerSettings = $null
            FileGrowths = $null
            DatabaseSettings = $null
            DatabaseObjects = $null
        }

    }

    process {
        $sql = (GetSQLFileContent -fileName "FindInvalidSettings.sql") -f $Database
        $results = Invoke-Sqlcmd @SqlCmdArguments -Query $sql -ErrorAction Stop -OutputAs DataSet

        $ret.ServerOptions = $results.Tables[1]
        $ret.ServerSettings = $results.Tables[3]
        $ret.FileGrowths = $results.Tables[5]
        $ret.DatabaseSettings = $results.Tables[7]
        $ret.DatabaseObjects = $results.Tables[9]
    }

    end {
        return $ret
    }
}
