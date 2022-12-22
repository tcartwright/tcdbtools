function New-DBSqlObjects {
    <#
    .SYNOPSIS
        Creates two objects:
        * The first is a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.
        * The second is a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections
        
    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .OUTPUTS
        Creates two objects:
        * return.SqlCmdArguments: The first is a custom PSObject, that can be splatted to Invoke-SqlCmd or any other command that takes similar arguments.
        * return.Server: The second is a type of [Microsoft.SqlServer.Management.Common.ServerConnection] used for SMO connections

    .EXAMPLE 

    PS> $objects = New-DBSqlObjects -ServerInstance "ServerName"
    PS> $server = $objects.Server                       # this is the SMO connection object
    PS> $sqlCmdArguments = $objects.SqlCmdArguments     # this object can be splatted to Invoke-SqlCmd or other functions that take the same parameters

    .LINK
        https://blog.kieranties.com/2018/03/26/write-information-with-colours
    #>    
    Param (
        [string]$ServerInstance, 
        [pscredential]$Credentials
    ) 

    begin {

    }

    process {
        # these sql cmd arguments will be used to splat the Invoke-SqlCmd arguments
        $SqlCmdArguments = @{
            ServerInstance = $ServerInstance
            Database = "master"
        }
        if ($Credentials) {
            $SqlCmdArguments.Add("Credential", $Credentials) | Out-Null
        }

        $serverConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
        $serverConnection.ServerInstance = $ServerInstance
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
        return [PSCustomObject] @{
            SqlCmdArguments = $SqlCmdArguments
            Server = $server
        }
    }
}
