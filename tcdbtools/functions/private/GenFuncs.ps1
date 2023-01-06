#Requires -Version 5.0
using namespace System.Management.Automation

Function Write-InformationColorized {
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

function GetSQLFileContent {
    param ([string]$fileName)
    return Get-Content -Path ([System.IO.Path]::Combine($script:tcdbtools_SqlDir, $fileName)) -Raw
}

# If the script has a hard time finding SMO, you can install the dbatools module and import it. Which ensures that SMO can be found.
if (-not (Get-Module -Name dbatools) -and (Get-Module -ListAvailable -Name dbatools)) {
    Write-Verbose "Importing dbatools"
    Import-Module dbatools
}

# load up SMO by default for all scripts.... hopefully. MSFT recently changed SMO to a nuget package which really jacks with finding it, or downloading it automatically
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$script:tcdbtools_SqlDir = [System.IO.Path]::Combine($scriptDir, "..\..\sql")


