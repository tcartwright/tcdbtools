function New-DBSMOServer {
    <#
    .SYNOPSIS
        Returns a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER ApplicationName
        The application name that will be supplied to the connection.

    .OUTPUTS
        Returns a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections

    .EXAMPLE

    PS> $server = New-DBSMOServer -ServerInstance "ServerName"

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Not needed')]
    [OutputType([Microsoft.SqlServer.Management.Smo.Server])]
    param (
        [string]$ServerInstance,
        [pscredential]$Credentials,
        [string]$ApplicationName = "tcdbtools"
    )

    begin {

    }

    process {
        $serverConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
        $serverConnection.ServerInstance = $ServerInstance
        $serverConnection.ApplicationName = $ApplicationName
        if ($Credentials) {
            $serverConnection.LoginSecure = $false
            $serverConnection.Login = $Credentials.UserName
            $serverConnection.SecurePassword = $Credentials.Password
        }

        $server = New-Object Microsoft.SqlServer.Management.Smo.Server($serverConnection)
        if ($null -eq $server.Version ) {
            throw "Unable to connect to: $ServerInstance"
            exit 1
        }
    }

    end {
        return $server
    }
}
