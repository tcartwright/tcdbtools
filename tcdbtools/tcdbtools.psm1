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

# private functions
. "$scriptDir\functions\private\Invoke-DBSafeShrink-privates.ps1"
. "$scriptDir\functions\private\Invoke-DBScriptObjects-privates.ps1"
. "$scriptDir\functions\private\Invoke-DBCompareServerSettings-privates.ps1"
. "$scriptDir\functions\private\GenFuncs.ps1"

Export-ModuleMember -Function Invoke-DBCompareServerSettings
Export-ModuleMember -Function Invoke-DBExtractCLRDLL
Export-ModuleMember -Function Invoke-DBScriptObjects
Export-ModuleMember -Function Invoke-DBMoveIndexes
Export-ModuleMember -Function Invoke-DBSafeShrink