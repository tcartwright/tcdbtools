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
    [OutputType([Microsoft.Data.SqlClient.SqlParameter])]
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

        $param = New-Object Microsoft.Data.SqlClient.SqlParameter($name, $type)

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
