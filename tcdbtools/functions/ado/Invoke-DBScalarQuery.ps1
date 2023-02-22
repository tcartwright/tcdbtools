function Invoke-DBScalarQuery {
    <#
    .SYNOPSIS
        Executes the query, and returns the first column of the first row in the result set returned by the query. Additional columns or rows are ignored.

    .DESCRIPTION
        Executes the query, and returns the first column of the first row in the result set returned by the query. Additional columns or rows are ignored.

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
            $cmd = New-Object system.Data.SqlClient.SqlCommand($sql,$conn)
            $cmd.CommandType = $CommandType
            $cmd.CommandTimeout=$timeout
            foreach($p in $parameters){
                $cmd.Parameters.Add($p) | Out-Null
            }
            return $cmd.ExecuteScalar()
        } finally {
            if ($cmd) {
                $cmd.Dispose();
            }
        }
    }
}
