#requires -Module PSScriptAnalyzer
Clear-Host

Remove-Module PSScriptAnalyzer -ErrorAction SilentlyContinue
Import-Module PSScriptAnalyzer

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

$scriptDir = [System.IO.Path]::Combine($scriptDir, "tcdbtools")

Invoke-ScriptAnalyzer -path $scriptDir -Recurse -Fix -ExcludeRule "PSUseSingularNouns" | Format-Table # , "PSUseShouldProcessForStateChangingFunctions", "PSAvoidGlobalVars"

Write-Host "DONE"

