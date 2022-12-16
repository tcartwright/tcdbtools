function GetObjectName($obj, [switch]$IncludeSchemaInNames){
    $ret = ""
    $details = ""
    $schemaNamePart = ""
    # check constraints may or may not have a column name, depending on what they did in the CK
    if ($obj.details1) {
        $details = "_$($obj.details1)"
    }
    if ($IncludeSchemaInNames.IsPresent) {
        $schemaNamePart = "_$($obj.schema_name)"
    }

    switch ($obj.type.Trim()) {
        { $_ -ieq "D" } { $ret = "DF$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "C" } { $ret = "CK$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "F" } { $ret = "FK$($schemaNamePart)_$($obj.table_name)_$($obj.details2)" }
        { $_ -ieq "PK" } { $ret = "PK$($schemaNamePart)_$($obj.table_name)" }
        { $_ -ieq "UQ" } { $ret = "UQ$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "UX" } { $ret = "UX$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "NC" } { $ret = "IX$($schemaNamePart)_$($obj.table_name)$details" }
        default { Write-Error "Unable to get constraint name for $($_)" }
    }

    return $ret
}

