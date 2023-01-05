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
        An array of sql parameters to use for the query. Can be created using New-SqlParameter.

    .PARAMETER timeout
        The command timeout for the query in seconds.

    .OUTPUTS
        The results of the query.
    #>    
	param (
		[Parameter(Mandatory=$true)]
		[System.Data.SqlClient.SqlConnection]$conn, 
		[Parameter(Mandatory=$true)]
		[string]$sql, 
		[System.Data.SqlClient.SqlParameter[]]$parameters, 
		[int]$timeout=30
	)
	
    try {
        $cmd = New-Object system.Data.SqlClient.SqlCommand($sql,$conn)
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
        An array of sql parameters to use for the query. Can be created using New-SqlParameter.

    .PARAMETER timeout
        The command timeout for the query in seconds.

    .OUTPUTS
        The results of the query.
    #>    
	param (
		[Parameter(Mandatory=$true)]
		[System.Data.SqlClient.SqlConnection]$conn, 
		[Parameter(Mandatory=$true)]
		[string]$sql, 
		[System.Data.SqlClient.SqlParameter[]]$parameters, 
		[int]$timeout=30
	)
	
    try {
        $cmd = New-Object system.Data.SqlClient.SqlCommand($sql, $conn)
        $cmd.CommandTimeout=$timeout
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
        An array of sql parameters to use for the query. Can be created using New-SqlParameter.

    .PARAMETER timeout
        The command timeout for the query in seconds.

    .OUTPUTS
        The SqlDataReader.
    #>    
	param (
		[Parameter(Mandatory=$true)]
		[System.Data.SqlClient.SqlConnection]$conn, 
		[Parameter(Mandatory=$true)]
		[string]$sql, 
		[System.Data.SqlClient.SqlParameter[]]$parameters, 
		[int]$timeout=30
	)
	
    try {
        $cmd = New-Object system.Data.SqlClient.SqlCommand($sql,$conn)
        $cmd.CommandTimeout=$timeout
        foreach($p in $parameters){
            $cmd.Parameters.Add($p) | Out-Null
        }
        return $cmd.ExecuteReader()
    } finally {
		if ($cmd) {
			$cmd.Dispose();
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
        An array of sql parameters to use for the query. Can be created using New-SqlParameter.

    .PARAMETER timeout
        The command timeout for the query in seconds.

    .OUTPUTS
        The results of the query.
    #>    
	param (
		[Parameter(Mandatory=$true)]
		[System.Data.SqlClient.SqlConnection]$conn, 
		[Parameter(Mandatory=$true)]
		[string]$sql, 
		[System.Data.SqlClient.SqlParameter[]]$parameters, 
		[int]$timeout = 30
	)
	
    try {
        $cmd = New-Object System.Data.SqlClient.SqlCommand($sql, $conn)
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

function New-SqlParameter {
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
	param (
		[Parameter(Mandatory=$true)]
		[string]$name, 
		[Parameter(Mandatory=$true)]
		[System.Data.SqlDbType]$type, 
		$value, 
        [Parameter(Mandatory=$true, ParameterSetName="Size")]
        [int]$size , 
        [Parameter(Mandatory=$true, ParameterSetName="ScaleAndPrecision")]
		[int]$scale, 
        [Parameter(Mandatory=$true, ParameterSetName="ScaleAndPrecision")]
		[int]$precision
	)
	
    if ($name[0] -ne "@") { $name = "@$name" }
 
    $param = New-Object System.Data.SqlClient.SqlParameter($name, $type) 
    
    if ($null -ne $value) { $param.Value = $value }
    if ($null -ne $size) { $param.Size = $size }
    if ($null -ne $scale) { $param.Scale = $scale }
    if ($null -ne $precision) { $param.Precision = $precision }
	
    return $param
}

function Get-InClauseParams {
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
    #>    
	param (
		[Parameter(Mandatory=$true)]
		[string]$prefix, 
		[Parameter(Mandatory=$true)]
		$values, 
		[Parameter(Mandatory=$true)]
		[System.Data.SqlDbType]$type, 
        [Parameter(Mandatory=$true, ParameterSetName="Size")]
        [int]$size, 
        [Parameter(Mandatory=$true, ParameterSetName="ScaleAndPrecision")]
		[int]$scale, 
        [Parameter(Mandatory=$true, ParameterSetName="ScaleAndPrecision")]
		[int]$precision
	)
	
    $params = New-Object System.Collections.ArrayList
    for  ($i=0; $i -le $values.Length -1; $i++) {
        $param = New-SqlParameter -name "@$prefix$i" -type $type -value $values[$i] -size $size -scale $scale -precision $precision
        $params.Add($param)
    }
    return $params
}

function Get-InClauseString {
    <#
    .SYNOPSIS
        Creates the string representation of the parameters that can be used with an IN clause.

    .DESCRIPTION
        Creates the string representation of the parameters that can be used with an IN clause.

    .PARAMETER parameters
        The IN clause parameters created by using Get-InClauseParams.

    .OUTPUTS
        A string representation of the parameters that can be used with an IN clause by concatenating the result into your query.

    .EXAMPLE 
        PS> $params = Get-InClauseParams -prefix "p_" -values $someList -type [System.Data.SqlDbType]::VarChar -size 50
        PS> $paramString = Get-InClauseString -parameters $params

        Assuming the list has 3 values in it, the function should return "@p_0, @p_1, @p_2". This string can now be concatenated 
        to the original query like so: "SELECT * FROM dbo.SomeTable AS [t] WHERE [t].id IN (@p_0, @p_1, @p_2)" 

        If multiple parameter lists are needed for multiple IN clauses, then different prefixes should be utilized for each list.

        By using a parameterized query you both block SQL Injection, and you also allow for execution plan re-use.
    #>    
	param (
		[Parameter(Mandatory=$true)]
		[System.Data.SqlClient.SqlParameter[]]$parameters
	)
	
    return [String]::Join(",", ($parameters | Select-Object -ExpandProperty ParameterName))
}