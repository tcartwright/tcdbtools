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
# private functions
. "$scriptDir\functions\private\Invoke-DBSafeShrink.ps1"
. "$scriptDir\functions\private\Invoke-DBScriptObjects.ps1"
. "$scriptDir\functions\private\Invoke-DBCompareServerSettings.ps1"
. "$scriptDir\functions\private\Invoke-DBRenameConstraints.ps1"
. "$scriptDir\functions\private\Find-DBValue.ps1"
. "$scriptDir\functions\private\GenFuncs.ps1"
. "$scriptDir\functions\private\Invoke-DBSqlAgentScripter.ps1"
. "$scriptDir\functions\private\Find-DBInvalidSettings.ps1"
. "$scriptDir\functions\private\Test-DBReadOnlyRouting.ps1"

# helper functions
. "$scriptDir\functions\New-DBScripterObject.ps1"
. "$scriptDir\functions\New-DBSMOServer.ps1"
. "$scriptDir\functions\New-DBSqlCmdArguments.ps1"
. "$scriptDir\functions\New-DBSQLConnection.ps1"
. "$scriptDir\functions\Invoke-SqlQueries.ps1"

# public functions
. "$scriptDir\functions\Invoke-DBMoveIndexes.ps1"
. "$scriptDir\functions\Invoke-DBSafeShrink.ps1"
. "$scriptDir\functions\Invoke-DBScriptObjects.ps1"
. "$scriptDir\functions\Invoke-DBExtractCLRDLL.ps1"
. "$scriptDir\functions\Invoke-DBCompareServerSettings.ps1"
. "$scriptDir\functions\Invoke-DBRenameConstraints.ps1"
. "$scriptDir\functions\Find-DBInvalidSettings.ps1"
. "$scriptDir\functions\Find-DBValue.ps1"
. "$scriptDir\functions\Test-DBReadOnlyRouting.ps1"
. "$scriptDir\functions\Find-DBColumnDataTypeDiscrepancies.ps1"
. "$scriptDir\functions\Invoke-DBDeployAgentJob.ps1"
. "$scriptDir\functions\Invoke-DBSqlAgentScripter.ps1"

# . "$scriptDir\functions\Invoke-Telnet.ps1" # debating on exposing this here. not really sql related.

# INIT FUNCTION
# this script MUST always be invoked last
. "$scriptDir\functions\private\ModuleInit.ps1"

Export-ModuleMember -Function Invoke-DBMoveIndexes
Export-ModuleMember -Function Invoke-DBSafeShrink
Export-ModuleMember -Function Invoke-DBScriptObjects
Export-ModuleMember -Function Invoke-DBExtractCLRDLL
Export-ModuleMember -Function Invoke-DBCompareServerSettings
Export-ModuleMember -Function Invoke-DBRenameConstraints
Export-ModuleMember -Function Find-DBInvalidSettings
Export-ModuleMember -Function Find-DBValue
Export-ModuleMember -Function Test-DBReadOnlyRouting
Export-ModuleMember -Function Find-DBColumnDataTypeDiscrepancies
Export-ModuleMember -Function Invoke-DBDeployAgentJob
Export-ModuleMember -Function Invoke-DBSqlAgentScripter

Export-ModuleMember -Function Invoke-DBScalarQuery
Export-ModuleMember -Function Invoke-DBNonQuery
Export-ModuleMember -Function Invoke-DBReaderQuery
Export-ModuleMember -Function Invoke-DBDataSetQuery
Export-ModuleMember -Function New-DBSqlParameter
Export-ModuleMember -Function Get-DBInClauseParams
Export-ModuleMember -Function Get-DBInClauseString

Export-ModuleMember -Function New-DBScripterObject
Export-ModuleMember -Function New-DBSqlCmdArguments
Export-ModuleMember -Function New-DBSMOServer
Export-ModuleMember -Function New-DBSQLConnection
Export-ModuleMember -Function Get-AllUserDatabases
#Export-ModuleMember -Function Invoke-Telnet

# these functions were not really db related, but I needed to make use of them, so I am exposing them
Export-ModuleMember -Function Write-InformationColorized
Export-ModuleMember -Function ConvertTo-Markdown