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
            $cmd = New-Object system.Data.SqlClient.SqlCommand($sql, $conn)
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
            $cmd.CommandTimeout = $timeout
            foreach($p in $parameters){
                $cmd.Parameters.Add($p) | Out-Null
            }
            [System.Data.SqlClient.SqlDataReader]$reader = $cmd.ExecuteReader()
            # the comma before the reader object is on purpose to force powershell to return this object AS IS
            return ,$reader
        } finally {
            if ($cmd) {
                $cmd.Dispose();
            }
        }
    }
}

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

function New-DBSqlParameter {
    <#
    .SYNOPSIS
        Creates a new instance of a SqlParameter object.

    .DESCRIPTION
        Creates a new instance of a SqlParameter object.

    .PARAMETER name
        The name of the SqlParameter.

    .PARAMETER type
        The SqlDbType of the parameter.

    .PARAMETER size
        The maximum size, in bytes, of the data within the column.

    .PARAMETER scale
        The number of decimal places to which Value is resolved.

    .PARAMETER precision
        The maximum number of digits used to represent the Value property.

    .OUTPUTS
        The SqlParameter.
    #>
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SqlParameter])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Not needed')]
    param (
        [Parameter(Mandatory=$true)]
        [string]$name,
        [Parameter(Mandatory=$true)]
        [System.Data.SqlDbType]$type,
        $value,
        [int]$size ,
        [int]$scale,
        [int]$precision
    )

    process {
        if ($name[0] -ne "@") { $name = "@$name" }

        $param = New-Object System.Data.SqlClient.SqlParameter($name, $type)

        if ($null -ne $value) { $param.Value = $value }
        if ($null -ne $size)  {
            $param.Size = $size
        } else {
            if ($null -ne $scale) { $param.Scale = $scale }
            if ($null -ne $precision) { $param.Precision = $precision }
        }

        return $param
    }
}

function Get-DBInClauseParams {
    <#
    .SYNOPSIS
        Can be used to create a set of parameters that can be used with an IN clause.

    .DESCRIPTION
        Can be used to create a set of parameters that can be used with an IN clause.

    .PARAMETER prefix
        The prefix to place in front of the parameter name. Must make the parameter name unique.

    .PARAMETER values
        The list of values to place into the parameters.

    .PARAMETER type
        The SqlDbType of the parameters.

    .PARAMETER size
        The maximum size, in bytes, of the data within the column.

    .PARAMETER scale
        The number of decimal places to which Value is resolved.

    .PARAMETER precision
        The maximum number of digits used to represent the Value property.

    .OUTPUTS
        The results of the query.

    .EXAMPLE
        PS> $list = 1..15
        PS> $params = Get-DBInClauseParams -prefix "p" -values $list -type Int

$params

    #>
    [CmdletBinding()]
    [OutputType([System.Data.SqlClient.SqlParameter[]])]
    param (
        [Parameter(Mandatory=$true)]
        [string]$prefix,
        [Parameter(Mandatory=$true)]
        $values,
        [Parameter(Mandatory=$true)]
        [System.Data.SqlDbType]$type,
        [int]$size,
        [int]$scale,
        [int]$precision
    )

    process {
        $params = New-Object 'System.Collections.Generic.List[System.Data.SqlClient.SqlParameter]'
        for  ($i=0; $i -le $values.Length -1; $i++) {
            $param = New-DBSqlParameter -name "@$prefix$i" -type $type -value $values[$i] -size $size -scale $scale -precision $precision
            $params.Add($param) | Out-Null
        }
        return $params.ToArray()
    }
}

function Get-DBInClauseString {
    <#
    .SYNOPSIS
        Creates the string representation of the parameters that can be used with an IN clause.

    .DESCRIPTION
        Creates the string representation of the parameters that can be used with an IN clause.

    .PARAMETER parameters
        The IN clause parameters created by using Get-DBInClauseParams.

    .PARAMETER delimiter
        The delimiter to use between the parameter names. Defaults to ",".

    .OUTPUTS
        A string representation of the parameters that can be used with an IN clause by concatenating the result into your query.

    .EXAMPLE
        PS> $params = Get-DBInClauseParams -prefix "p_" -values $someList -type [System.Data.SqlDbType]::VarChar -size 50
        PS> $paramString = Get-DBInClauseString -parameters $params

        Assuming the list has 3 values in it, the function should return "@p_0, @p_1, @p_2". This string can now be concatenated
        to the original query like so: "SELECT * FROM dbo.SomeTable AS [t] WHERE [t].id IN (@p_0, @p_1, @p_2)"

        If multiple parameter lists are needed for multiple IN clauses, then different prefixes should be utilized for each list.

        By using a parameterized query you both block SQL Injection, and you also allow for execution plan re-use.

    .EXAMPLE
        PS> $list = 1..15
        PS> $params = Get-DBInClauseParams -prefix "p" -values $list -type Int
        PS> $paramStr = Get-DBInClauseString -parameters $params
        PS> $params
        PS> $paramStr

    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory=$true)]
        [System.Data.SqlClient.SqlParameter[]]$parameters,
        [string]$delimiter = ","
    )

    process {
        $names = $parameters | ForEach-Object { $_.ParameterName }
        return $names -join $delimiter
    }
}