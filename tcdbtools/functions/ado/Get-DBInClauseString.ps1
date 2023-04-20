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
        PS> $params = Get-DBInClauseParams -prefix "p_" -values $someList -type [Microsoft.Data.SqlDbType]::VarChar -size 50
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
        [Microsoft.Data.SqlClient.SqlParameter[]]$parameters,
        [string]$delimiter = ","
    )

    process {
        $names = $parameters | ForEach-Object { $_.ParameterName }
        return $names -join $delimiter
    }
}