function New-DBSqlCmdArguments {
    <#
    .SYNOPSIS
        Creates a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER Database
        Specifies the name of the database.

    .PARAMETER ApplicationName
        The application name that will be supplied to the connection.

    .OUTPUTS
        Creates a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.

    .EXAMPLE

    PS> $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance "ServerName"

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Not needed')]
    param (
        [string]$ServerInstance,
        [pscredential]$Credentials,
        [string]$Database = "master",
        [string]$ApplicationName = "tcdbtools"
    )

    begin {

    }

    process {
        # these sql cmd arguments can be used to splat the Invoke-SqlCmd arguments
        $SqlCmdArguments = @{
            ServerInstance = $ServerInstance
            Database = $Database
            ApplicationName = $ApplicationName
        }
        if ($Credentials) {
            $SqlCmdArguments.Add("Credential", $Credentials)
        }
    }

    end {
        return $SqlCmdArguments
    }
}
