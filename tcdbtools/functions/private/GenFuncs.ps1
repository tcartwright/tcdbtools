#Requires -Version 5.0
using namespace System.Management.Automation

Function Write-InformationColored {
    <#
        .SYNOPSIS
            Writes messages to the information stream, optionally with
            color when written to the host.
        .DESCRIPTION
            An alternative to Write-Host which will write to the information stream
            and the host (optionally in colors specified) but will honor the
            $InformationPreference of the calling context.
            In PowerShell 5.0+ Write-Host calls through to Write-Information but
            will _always_ treats $InformationPreference as 'Continue', so the caller
            cannot use other options to the preference variable as intended.

        .LINK
            https://blog.kieranties.com/2018/03/26/write-information-with-colours
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object]$MessageData,
        [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor, # Make sure we use the current colours by default
        [ConsoleColor]$BackgroundColor = $Host.UI.RawUI.BackgroundColor,
        [Switch]$NoNewline
    )

    $msg = [HostInformationMessage]@{
        Message         = $MessageData
        ForegroundColor = $ForegroundColor
        BackgroundColor = $BackgroundColor
        NoNewline       = $NoNewline.IsPresent
    }

    Write-Information $msg
}

function InitSqlObjects($ServerInstance, [pscredential]$Credentials) {
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

    return [PSCustomObject] @{
        SqlCmdArguments = $SqlCmdArguments
        Server = $server
    }
}

function GetSQLConnection {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string]$Database,
        [pscredential]$Credentials,
        [string]$AppName = "tcdbtools"
    )

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
    return $connection
}

# If the script has a hard time finding SMO, you can install the dbatools module and import it. Which ensures that SMO can be found.
if (-not (Get-Module -Name dbatools) -and (Get-Module -ListAvailable -Name dbatools)) {
    Write-Verbose "Importing dbatools"
    Import-Module dbatools
}

# load up SMO by default for all scripts.... hopefully. MSFT recently changed SMO to a nuget package which really jacks with finding it, or downloading it automatically
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null


