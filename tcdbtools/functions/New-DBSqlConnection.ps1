function New-DBSqlConnection {
    <#
    .SYNOPSIS
        Creates a SqlConnection

    .DESCRIPTION
        Creates a SqlConnection

    .PARAMETER ServerInstance
        Specifies the database server hostname.

    .PARAMETER Database
        Specifies the name of the database.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER MultipleActiveResultSets
        When true, an application can maintain multiple active result sets (MARS). When false, an application must process or cancel all result sets from one batch before it can execute any other batch on that connection.

    .PARAMETER ApplicationIntent
        Specifies a value for ApplicationIntent. Possible values are ReadWrite and ReadOnly.

    .PARAMETER ConnectTimeout
        Gets or sets the length of time (in seconds) to wait for a connection to the server before terminating the attempt and generating an error.

    .PARAMETER ApplicationName
        The application name that will be supplied to the connection.

    .OUTPUTS
        The SqlConnection object

    .EXAMPLE
        PS> $connection = New-DBSQLConnection

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Not needed')]
    [OutputType([System.Data.SqlClient.SqlConnection])]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database,
        [pscredential]$Credentials,
        [switch]$MultipleActiveResultSets,
        [ValidateSet("ReadWrite", "ReadOnly")]
        [string]$ApplicationIntent = "ReadWrite",
        [int]$ConnectTimeout,
        [string]$ApplicationName = "tcdbtools"
    )

    begin {

    }

    process {
        # in powershell you cannot use the property names of the builder, you have to use the dictionary keys
        $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
        # $builder.Keys | Sort-Object
        $builder["Data Source"] = $ServerInstance
        $builder["Initial Catalog"] = $Database
        $builder["Application Name"] = $ApplicationName
        $builder["Integrated Security"] = -not $Credentials
        $builder["ApplicationIntent"] = $ApplicationIntent

        if ($MultipleActiveResultSets.IsPresent) {
            $builder["MultipleActiveResultSets"] = $true
        }
        if ($ConnectTimeout) {
            $builder["Connect Timeout"] = $ConnectTimeout
        }

        $connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString);
        if ($Credentials) {
            $connection.Credential = $Credentials
        }
    }

    end {
        return $connection
    }
}
