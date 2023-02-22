function Invoke-DBDataSetQuery {
    <#
    .SYNOPSIS
        Executes a Transact-SQL statement against the connection and returns a DataSet containing a
        DataTable for each result set returned.

    .DESCRIPTION
        Executes a Transact-SQL statement against the connection and returns a DataSet containing a
        DataTable for each result set returned.

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
    [OutputType([System.Data.DataSet])]
    param (
        [Parameter(Mandatory=$true)]
        [Alias("Connection")]
        [System.Data.SqlClient.SqlConnection]$conn,
        [Parameter(Mandatory=$true)]
        [Alias("Query")]
        [string]$sql,
        [System.Data.CommandType]$CommandType = [System.Data.CommandType]::Text,
        [System.Data.SqlClient.SqlParameter[]]$parameters,
        [int]$timeout = 30
    )

    process {
        try {
            $cmd = New-Object System.Data.SqlClient.SqlCommand($sql, $conn)
            $cmd.CommandType = $CommandType
            $cmd.CommandTimeout=$timeout
            foreach($p in $parameters){
                $cmd.Parameters.Add($p) | Out-Null
            }
            $ds = New-Object System.Data.DataSet
            $da = New-Object System.Data.SqlClient.SqlDataAdapter($cmd)
            $da.Fill($ds) | Out-Null

            return $ds
        } finally {
            if ($cmd) {
                $cmd.Dispose();
            }
        }
    }
}