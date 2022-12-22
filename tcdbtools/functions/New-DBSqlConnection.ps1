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
    
    .PARAMETER AppName    
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
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database,
        [pscredential]$Credentials,
        [string]$AppName = "tcdbtools"
    )

    begin {

    }

    process {
        # in powershell you cannot use the proper names of the builder, you have to use the dictionary keys
        $builder = [System.Data.SqlClient.SqlConnectionStringBuilder]::new()
        $builder["Data Source"] = $ServerInstance
        $builder["Initial Catalog"] = $Database
        $builder["Application Name"] = $AppName
        $builder["Integrated Security"] = -not $Credentials

        $connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString);
        if ($Credentials) {
            $connection.Credential = $Credentials
        }
    }

    end {
        return $connection
    }
}
