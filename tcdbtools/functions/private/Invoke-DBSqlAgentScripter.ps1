[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "")]
param()

# # this type is used for the parameters for the Invoke-DBSqlAgentScripter function
# Add-Type -TypeDefinition @"
#     [System.Flags]
#     public enum SQLAgentScripterOptions {
#         Alerts = 1,
#         Operators = 2,
#         OperatorCategories = 4,
#         Jobs = 8,
#         JobCategories = 16,
#         All = Alerts | Operators | OperatorCategories | Jobs | JobCategories
#     }
# "@

# [Flags()] enum SQLAgentScripterOptions {
#     Alerts = 1
#     Operators = 2
#     OperatorCategories = 4
#     Jobs = 8
#     JobCategories = 16
#     All = (Alerts -bor Operators -bor OperatorCategories -bor Jobs -bor JobCategories)
# }


[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '', Scope="Function", Target="*")]
$modifyAgentScript = {
    Param(
        [string]$createScript,
        [string]$objectName,
        [switch]$DoNotScriptJobDrop,
        [switch]$DoNotGenerateForSqlCmd,
        [string]$scriptHeaderReplaceRegex,
        [string]$scriptHeaderReplace
    )
    # if we are generating the job for sql cmd we need to replace any dollar signs with our own custom $ token
    # AND if the script contains a $ in the first place
    if (!$DoNotGenerateForSqlCmd.IsPresent -and $createScript.Contains("`$")) {
        $createScript = ":setvar dollar `"`$`"`r`n$($createScript -replace "\`$", "`$(dollar)")"
    }
    return $createScript;
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '', Scope="Function", Target="*")]
$modifyAgentJobScript = {
    Param(
        [string]$createScript,
        [string]$objectName,
        [switch]$DoNotScriptJobDrop,
        [switch]$DoNotGenerateForSqlCmd,
        [string]$scriptHeaderReplaceRegex,
        [string]$scriptHeaderReplace
    )
    #only add the drop statements if they want us to
    if (!$DoNotScriptJobDrop.IsPresent) {
        $dropJobSql = ($scriptHeaderReplace -ireplace "<<job_name>>", $objectName)
        $createScript = $createScript -ireplace $scriptHeaderReplaceRegex, $dropJobSql
    }
    # if we are generating the job for sql cmd we need to replace any dollar signs with our own custom $ token
    # AND if the script contains a $ in the first place
    if (!$DoNotGenerateForSqlCmd.IsPresent -and $createScript.Contains("`$")) {
        $createScript = ":setvar dollar `"`$`"`r`n$($createScript -replace "\`$", "`$(dollar)")"
    }
    return $createScript;
}

function WriteAgentScriptFile {
    param (
        $smoObject,
        [Microsoft.SqlServer.Management.Smo.ScriptingOptions]$scriptOptions,
        [ScriptBlock]$modifyScriptBlock,
        [switch]$DoNotScriptJobDrop,
        [switch]$DoNotGenerateForSqlCmd,
        [string]$scriptHeaderReplaceRegex,
        [string]$scriptHeaderReplace
    )

    $typeName = $smoObject.GetType().Name

    if ($typeName.EndsWith("y")) {
        $collectionName = "$($typeName.SubString(0, $typeName.Length -1))ies"
    } else {
        $collectionName = "$($typeName)s"
    }

    $validName = (ReplaceInvalidPathChars -str $smoObject.Name)
    try {
        $scriptFolder =  [System.Io.Path]::Combine($outFolder, $collectionName)

        if (!(Test-Path $scriptFolder -PathType Container)) {
            New-Item $scriptFolder -ItemType Directory -Force | Out-Null
        }

        Write-Information "Generating $($typeName): $validName.sql"
        if (!$scriptOptions) {
            $scriptOptions = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions
        }

        $script = "$($smoObject.Script($scriptOptions))`r`nGO`r`n"

        if ($modifyScriptBlock) {
            $script = &$modifyScriptBlock `
                -createScript $script -objectName ($smoObject.Name) `
                -DoNotScriptJobDrop:$DoNotScriptJobDrop.IsPresent `
                -DoNotGenerateForSqlCmd:$DoNotGenerateForSqlCmd.IsPresent `
                -scriptHeaderReplaceRegex $scriptHeaderReplaceRegex `
                -scriptHeaderReplace $scriptHeaderReplace
        }

        $script | Out-File ([System.Io.Path]::Combine($scriptFolder, "$validName.sql")) -Force -Encoding ascii
    } catch {
        Write-Error "`tException writing $typeName ($validName):`r`n`t$($_.Exception.GetBaseException().Message)"
        continue
    }
}

