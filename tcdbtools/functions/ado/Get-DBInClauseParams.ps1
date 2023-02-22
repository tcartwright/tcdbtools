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
