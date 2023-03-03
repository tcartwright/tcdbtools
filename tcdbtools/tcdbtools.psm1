#Requires -Version 5.0
#Requires -Modules SqlServer

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

# functions
$scripts = Get-ChildItem "$scriptDir\functions\" -Filter "*.ps1" -Recurse |
    Where-Object { $_.Name -inotmatch "(?:ModuleInit|template)\.ps1" } |
    Sort-Object FullName |
    Select-Object -ExpandProperty FullName

foreach($script in $scripts) {
    . $script
}

# INIT FUNCTION: this script MUST always be invoked last
. "$scriptDir\functions\private\ModuleInit.ps1"

# export any and all functions with a dash in the name
Export-ModuleMember -Function *-*

# add and export aliases
New-Alias -Name New-DBUserCredential -Value Set-DBUserCredential
Export-ModuleMember -Alias New-DBUserCredential -Function Set-DBUserCredential

