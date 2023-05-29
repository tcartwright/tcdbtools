#requires -Module PSScriptAnalyzer
Clear-Host

Import-Module PSScriptAnalyzer

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

$scriptDir = [System.IO.Path]::Combine($scriptDir, "tcdbtools")

# the exclusions here must match the exclusions in ps_gallery_module.yml
$excludes = "PSUseSingularNouns", "PSAvoidAssignmentToAutomaticVariable", "PSReviewUnusedParameter"
Invoke-ScriptAnalyzer -path $scriptDir -Recurse -Fix -ExcludeRule $excludes | Format-Table
Write-Information "DONE" -InformationAction Continue

