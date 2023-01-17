[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '', Scope="Function", Target="*")]
$GetObjectNameFunction = {
    param ($obj, [switch]$IncludeSchemaInNames)
    $ret = ""
    $details = ""
    $schemaNamePart = ""

    # check constraints may or may not have a column name, depending on what they did in the CK
    if (-not [string]::IsNullOrWhiteSpace($obj.details1)) {
        $details = "_$($obj.details1)"
    }
    if ($IncludeSchemaInNames.IsPresent) {
        $schemaNamePart = "_$($obj.schema_name)"
    }

    switch ($obj.type.Trim()) {
        { $_ -ieq "D" } { $ret = "DF$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "C" } { $ret = "CK$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "F" } {
            $remoteTable = "_$($obj.details2)"
            if ($IncludeSchemaInNames.IsPresent) {
                $remoteTable = "_$($obj.details1)_$($obj.details2)"
            }
            $ret = "FK$($schemaNamePart)_$($obj.table_name)$($remoteTable)"
        }
        { $_ -ieq "PK" } { $ret = "PK$($schemaNamePart)_$($obj.table_name)" }
        { $_ -ieq "UQ" } { $ret = "UQ$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "UX" } { $ret = "UX$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "NC" } { $ret = "IX$($schemaNamePart)_$($obj.table_name)$details" }
        default { Write-Error "Unable to get constraint name for $($_)" }
    }

    return $ret
}

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '', Scope="Function", Target="*")]
$NameExistsFunction = {
    param ($newName, $renames)

    for ($i = 1; $i -lt 1000; $i++) {
        $suffix = "00$i"
        $suffix = $suffix.Substring($suffix.Length - 3)
        $tmpName = "$($newName)_$suffix"
        if (-not $renames.ContainsKey($tmpName)) {
            $newName = $tmpName
            break;
        }
    }
    return $newName
}
