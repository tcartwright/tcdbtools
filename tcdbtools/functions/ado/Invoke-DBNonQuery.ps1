function Invoke-DBNonQuery {
    <#
    .SYNOPSIS
        Executes a Transact-SQL statement against the connection and returns the number of rows affected.

    .DESCRIPTION
        Executes a Transact-SQL statement against the connection and returns the number of rows affected.

    .PARAMETER conn
        The sql server connection to use when creating the command.

    .PARAMETER sql
        The sql to use for the query.

    .PARAMETER parameters
        An array of sql parameters to use for the query. Can be created using New-DBSqlParameter.

    .PARAMETER timeout
        The command timeout for the query in seconds.

    .OUTPUTS
        The results of the query.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [Alias("Connection")]
        [Microsoft.Data.SqlClient.SqlConnection]$conn,
        [Parameter(Mandatory=$true)]
        [Alias("Query")]
        [string]$sql,
        [System.Data.CommandType]$CommandType = [System.Data.CommandType]::Text,
        [Microsoft.Data.SqlClient.SqlParameter[]]$parameters,
        [int]$timeout=30
    )

    process {
        try {
            $cmd = New-Object Microsoft.Data.SqlClient.SqlCommand($sql, $conn)
            $cmd.CommandType = $CommandType
            $cmd.CommandTimeout = $timeout
            foreach($p in $parameters){
                $cmd.Parameters.Add($p) | Out-Null
            }
            return $cmd.ExecuteNonQuery()
        } finally {
            if ($cmd) {
                $cmd.Dispose();
            }
        }
    }
}
