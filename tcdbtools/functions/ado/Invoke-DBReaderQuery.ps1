function Invoke-DBReaderQuery {
    <#
    .SYNOPSIS
        Sends the CommandText to the Connection and builds a SqlDataReader.

    .DESCRIPTION
        Sends the CommandText to the Connection and builds a SqlDataReader.

    .PARAMETER conn
        The sql server connection to use when creating the command.

    .PARAMETER sql
        The sql to use for the query.

    .PARAMETER parameters
        An array of sql parameters to use for the query. Can be created using New-DBSqlParameter.

    .PARAMETER timeout
        The command timeout for the query in seconds.

    .OUTPUTS
        The SqlDataReader.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '', Justification='Correct type')]
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SqlDataReader])]
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
            [Microsoft.Data.SqlClient.SqlDataReader]$reader = $cmd.ExecuteReader()
            # the comma before the reader object is on purpose to force powershell to return this object AS IS
            return ,$reader
        } finally {
            if ($cmd) {
                $cmd.Dispose();
            }
        }
    }
}