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
        The databases.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER Timeout
         The wait time (in seconds) before terminating the attempt to execute a command and generating an error. The default is 30 seconds.

    .OUTPUTS

    .LINK

    #>
    Param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [int]$Timeout = 30
    )

    begin {
        $sqlCon = New-DBSqlObjects -ServerInstance $ServerInstance -Credentials $Credentials
        $SqlCmdArguments = $sqlCon.SqlCmdArguments
        $ret = New-Object 'System.Collections.Generic.List[System.Object]'
        $query = GetSQLFileContent -fileName "FindColumnDataTypeDifferences.sql"
    }

    process {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $results = Invoke-SqlCmd @SqlCmdArguments -As DataRows -Query $query -QueryTimeout $Timeout
            if ($results) {
                $ret.AddRange($results)
            }
        }
    }

    end {
        return $ret | Sort-Object -Property column_name, table_name, type_name_desc
    }
}
