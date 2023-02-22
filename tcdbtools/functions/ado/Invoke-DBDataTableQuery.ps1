function Invoke-DBDataTableQuery {
    <#
    .SYNOPSIS
        Executes the query, and returns a DataTable of the results.

    .DESCRIPTION
        Executes the query, and returns a DataTable of the results.

    .PARAMETER conn
        The sql server connection to use when creating the command.

    .PARAMETER sql
        The sql to use for the query.

    .PARAMETER parameters
        An array of sql parameters to use for the query. Can be created using New-DBSqlParameter.

    .PARAMETER timeout
        The command timeout for the query in seconds.

    .OUTPUTS
        The DataTable.
    #>
    [CmdletBinding()]
    [OutputType([System.Data.DataTable])]
    param (
        [Parameter(Mandatory=$true)]
        [Alias("Connection")]
        [System.Data.SqlClient.SqlConnection]$conn,
        [Parameter(Mandatory=$true)]
        [Alias("Query")]
        [string]$sql,
        [System.Data.CommandType]$CommandType = [System.Data.CommandType]::Text,
        [System.Data.SqlClient.SqlParameter[]]$parameters,
        [int]$timeout=30
    )

    process {
        try {
            $reader = Invoke-DBReaderQuery -conn $conn -sql $sql -CommandType $CommandType -parameters $parameters -timeout $timeout
            $table = New-Object System.Data.DataTable
            $table.Load($reader)
            return $table
        } finally {
            if ($reader) {
                $reader.Dispose();
            }
        }
    }
}
