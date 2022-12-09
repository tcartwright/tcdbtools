<#
    .Synopsis
        This Module contains functions to help with automating various SQL Server functionality.

    .Description
        This Module contains functions to help with automating various SQL Server functionality.

    .Notes
        Author       : Tim Cartwright <tcartwright@users.noreply.github.com>
        Homepage     : https://github.com/tcartwright/tcdbtools

#>

$PsIniModuleHome = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# public functions
. "$PsIniModuleHome\functions\Invoke-DBMoveIndexes.ps1"
. "$PsIniModuleHome\functions\Invoke-DBSafeShrink.ps1"
. "$PsIniModuleHome\functions\Invoke-DBScriptObjects.ps1"
. "$PsIniModuleHome\functions\Invoke-DBExtractCLRDLL.ps1"
. "$PsIniModuleHome\functions\Invoke-DBCompareServerSettings.ps1"

# private functions
. "$PsIniModuleHome\functions\private\Invoke-DBSafeShrink-functions.ps1"
. "$PsIniModuleHome\functions\private\Invoke-DBScriptObjects-functions.ps1"
. "$PsIniModuleHome\functions\private\Invoke-DBCompareServerSettings-functions.ps1"
. "$PsIniModuleHome\functions\private\GenFuncs.ps1"

Export-ModuleMember -Function Invoke-DBCompareServerSettings
Export-ModuleMember -Function Invoke-DBExtractCLRDLL
Export-ModuleMember -Function Invoke-DBScriptObjects
Export-ModuleMember -Function Invoke-DBMoveIndexes
Export-ModuleMember -Function Invoke-DBSafeShrink