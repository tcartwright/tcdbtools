function New-DBSqlConnection {
    <#
    .SYNOPSIS
        Creates a Microsoft.Data.SqlClient.SqlConnection

    .DESCRIPTION
        Creates a Microsoft.Data.SqlClient.SqlConnection

    .PARAMETER ServerInstance
        The name or network address of the instance of SQL Server to connect to.
    .PARAMETER Database
        The name of the database associated with the connection.
    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.
    .PARAMETER AuthenticationMethod
        The authentication method used for Connecting to SQL Database By Using Azure Active Directory Authentication.
    .PARAMETER MultipleActiveResultSets
        When true, an application can maintain multiple active result sets (MARS). When false, an application must process or cancel all result sets from one batch before it can execute any other batch on that connection.
    .PARAMETER ApplicationIntent
        Specifies a value for ApplicationIntent. Possible values are ReadWrite and ReadOnly.
    .PARAMETER ApplicationName
        The application name that will be supplied to the connection.
    .PARAMETER Encrypt
        A SqlConnectionEncryptOption value since version 5.0 or a Boolean value for the earlier versions that indicates whether TLS encryption is required for all data sent between the client and server.
    .PARAMETER TrustServerCertificate
        A value that indicates whether the channel will be encrypted while bypassing walking the certificate chain to validate trust.
    .PARAMETER ColumnEncryptionSetting
        The column encryption settings for the connection string builder.
    .PARAMETER ConnectTimeout
        Gets or sets the length of time (in seconds) to wait for a connection to the server before terminating the attempt and generating an error.
    .PARAMETER CommandTimeout
        The default wait time (in seconds) before terminating the attempt to execute a command and generating an error. The default is 30 seconds.
    .PARAMETER LoadBalanceTimeout
        The minimum time, in seconds, for the connection to live in the connection pool before being destroyed.
    .PARAMETER WorkstationID
        The name of the workstation connecting to SQL Server.
    .PARAMETER MinPoolSize
        The minimum number of connections allowed in the connection pool for this specific connection string.
    .PARAMETER MaxPoolSize
        The maximum number of connections allowed in the connection pool for this specific connection string.
    .PARAMETER Pooling
        A Boolean value that indicates whether the connection will be pooled or explicitly opened every time that the connection is requested.

    .OUTPUTS
        The SqlConnection object

    .EXAMPLE
        PS> $connection = New-DBSQLConnection

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright

    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Not needed')]
    [OutputType([Microsoft.Data.SqlClient.SqlConnection])]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database,
        [pscredential]$Credentials,
        [Microsoft.Data.SqlClient.SqlAuthenticationMethod]$AuthenticationMethod,
        [switch]$MultipleActiveResultSets,
        [Microsoft.Data.SqlClient.ApplicationIntent]$ApplicationIntent,
        [string]$ApplicationName = "tcdbtools",
        [ValidateSet("Mandatory", "Optional", "Strict")]
        [string]$Encrypt = "Optional",
        [switch]$TrustServerCertificate,
        [Microsoft.Data.SqlClient.SqlConnectionColumnEncryptionSetting]$ColumnEncryptionSetting,
        [int]$ConnectTimeout,
        [int]$CommandTimeout = 30,
        [int]$LoadBalanceTimeout,
        [ValidateLength(0, 128)]
        [string]$WorkstationID,
        [int]$MinPoolSize,
        [int]$MaxPoolSize,
        [bool]$Pooling
    )

    begin {

    }

    process {
        # in powershell you cannot use the property names of the builder, you have to use the dictionary keys
        $builder = [Microsoft.Data.SqlClient.SqlConnectionStringBuilder]::new()
        # $builder.Keys | Sort-Object
        $builder["Data Source"] = $ServerInstance
        $builder["Initial Catalog"] = $Database
        $builder["Application Name"] = $ApplicationName
        # only set integrated if the authentication method is not passed in
        if (-not $AuthenticationMethod) { $builder["Integrated Security"] = -not $Credentials }
        $builder["Encrypt"] = $Encrypt

        if ($TrustServerCertificate.IsPresent) { $builder["Trust Server Certificate"] = $true }
        if ($ColumnEncryptionSetting) { $builder["ColumnEncryptionSetting"] = $ColumnEncryptionSetting }

        if ($ApplicationIntent) { $builder["ApplicationIntent"] = $ApplicationIntent }
        if ($MultipleActiveResultSets.IsPresent) { $builder["MultipleActiveResultSets"] = $true }
        if ($WorkstationID) { $builder["Workstation ID"] = $WorkstationID }

        if ($Pooling) { $builder["Pooling"] = $Pooling }
        if ($MinPoolSize) { $builder["Min Pool Size"] = $MinPoolSize }
        if ($MaxPoolSize) { $builder["Max Pool Size"] = $MaxPoolSize }

        if ($ConnectTimeout) { $builder["Connect Timeout"] = $ConnectTimeout }
        if ($CommandTimeout) { $builder["Command Timeout"] = $CommandTimeout }
        if ($LoadBalanceTimeout) { $builder["Load Balance Timeout"] = $LoadBalanceTimeout }

        $connection = New-Object Microsoft.Data.SqlClient.SqlConnection($builder.ConnectionString);
        if ($Credentials) {
            if ($Credentials.Password -and -not $Credentials.Password.IsReadOnly()) {
                $Credentials.Password.MakeReadOnly()
            }
            $connection.Credential = New-Object Microsoft.Data.SqlClient.SqlCredential($Credentials.username, $Credentials.password)
        }
    }

    end {
        return $connection
    }
}
