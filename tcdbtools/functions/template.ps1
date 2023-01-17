function template {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Databases
        The databases.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .OUTPUTS

    .EXAMPLE

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string[]]$Databases,
        [pscredential]$Credentials
    )

    begin {
        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstance -Credentials $Credentials
        $server = New-DBSMOServer -ServerInstance $ServerInstance -Credentials $Credentials
    }

    process {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database]
            Write-Information $db.Name
        }
    }

    end {

    }
}
