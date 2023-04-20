function Find-DBColumnDataTypeDiscrepancies {
    <#
    .SYNOPSIS
        Scans the database for columns in different tables that have the same names, but differ by data type.

    .DESCRIPTION
        Scans the database for columns in different tables that have the same names, but differ by data type. Helps to track down and unify data types.
        This can also help prevent potential rounding errors with decimals that may get stored in different tables.

        Obviously, there are some columns with the same name that you do not care if they have different data types or sizes. This report is there to help
        you find the ones that do matter.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Databases
        The databases operate on. If the value ALL_USER_DATABASES is passed in then, the renames will be applied to all user databases.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER Timeout
         The wait time (in seconds) before terminating the attempt to execute a command and generating an error. The default is 30 seconds.

    .OUTPUTS

    .EXAMPLE
        Finds all column data type discrepancies across all user databases.

        Find-DBColumnDataTypeDiscrepancies `
            -ServerInstance "ServerName" `
            -Databases "ALL_USER_DATABASES"


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
        [Parameter(Mandatory=$true)]
        [ValidateCount(1, 9999)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [int]$Timeout = 30
    )

    begin {
        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstance -Credentials $Credentials
        $ret = New-Object 'System.Collections.Generic.List[System.Object]'
        $query = GetSQLFileContent -fileName "FindColumnDataTypeDifferences.sql"
    }

    process {
        # if they passed in ALL_USER_DATABASES get all database names
        $Databases = Get-AllUserDatabases -Databases $Databases -SqlCmdArguments $SqlCmdArguments

        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            Write-Information "Querying: $Database"
            $tbl = Invoke-SqlCmd @SqlCmdArguments -As DataTables -Query $query -QueryTimeout $Timeout -Encrypt Optional
            $results = ConvertFrom-DataTable -DataTable $tbl
            if ($results) {
                $ret.AddRange($results)
            }
        }
    }

    end {
        return $ret | Sort-Object -Property db_name, column_name, table_name, type_name_desc
    }
}
