<#
    .Synopsis
        This Module contains functions to help with automating various SQL Server functionality.

    .Description
        This Module contains functions to help with automating various SQL Server functionality.

    .Notes
        Author       : Tim Cartwright <tcartwright@users.noreply.github.com>
        Homepage     : https://github.com/tcartwright/tcdbtools

#>

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# public functions
. "$scriptDir\functions\Invoke-DBMoveIndexes.ps1"
. "$scriptDir\functions\Invoke-DBSafeShrink.ps1"
. "$scriptDir\functions\Invoke-DBScriptObjects.ps1"
. "$scriptDir\functions\Invoke-DBExtractCLRDLL.ps1"
. "$scriptDir\functions\Invoke-DBCompareServerSettings.ps1"
. "$scriptDir\functions\Invoke-DBRenameConstraints.ps1"
. "$scriptDir\functions\New-DBScripterObject.ps1"
. "$scriptDir\functions\New-DBSqlObjects.ps1"
. "$scriptDir\functions\New-DBSQLConnection.ps1"
. "$scriptDir\functions\Invoke-Telnet.ps1" # debating on exposing this here. not really sql related.

# private functions
. "$scriptDir\functions\private\Invoke-DBSafeShrink.ps1"
. "$scriptDir\functions\private\Invoke-DBScriptObjects.ps1"
. "$scriptDir\functions\private\Invoke-DBCompareServerSettings.ps1"
. "$scriptDir\functions\private\Invoke-DBRenameConstraints.ps1"
. "$scriptDir\functions\private\GenFuncs.ps1"

Export-ModuleMember -Function Invoke-*
Export-ModuleMember -Function New-*
Export-ModuleMember -Function Write-InformationColorized
#Export-ModuleMember -Function Invoke-Telnet