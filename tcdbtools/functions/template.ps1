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

    #>
    Param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string[]]$Databases,
        [pscredential]$Credentials
    )

    begin {
        $sqlCon = New-DBSqlObjects -ServerInstance $ServerInstance -Credentials $Credentials
        $SqlCmdArguments = $sqlCon.SqlCmdArguments
        $server = $sqlCon.server
    }

    process {
        foreach($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $db = $server.Databases[$Database]
        
        }
    }

    end {

    }
}
