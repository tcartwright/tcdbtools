# Invoke-DBRenameConstraints
**Author** Tim Cartwright

## Synopsis
Will rename all indexes and constraints to match naming conventions.

## Description
Will rename all indexes and constraints to match naming conventions. Any constraint name that already matches the expected convention will be skipped unless -Force is supplied. Custom naming conventions can be used.

The default naming conventions are as follows:

| Type | Default Name |
| ---- | ------------ |
| Default Constraint | "DF_**TableName**_**ColumnName**" |
| Check Constraint | "CK_**TableName**_**ColumnName**" |
| Foreign Key | "FK_**TableName**_**RemoteTableName**" |
| Primary Key | "PK_**TableName**" |
| Unique Constraint | "UQ_**TableName**_**ColumnName**" |
| Unique Index | "UX_**TableName**_**ColumnName**" |
| Non-Clustered Index | "IX_**TableName**_**ColumnName**" |

The column name picked will be the first column name used in the index or constraint. With complex predicates and or the use of functions in check constraints the column name sometimes cannot be determined by SQL Server and will return null.

When there are conflicts a number will be suffixed on to the end of the name until a unique name can be found. Starting with _001, _002, and so on up until _999. 

## Syntax
    Invoke-DBRenameConstraints 
        [-ServerInstance] <String> 
        [-Databases] <String[]> 
        [[-Credentials] <PSCredential>] 
        [-IncludeSchemaInNames ] 
        [-Force ] 
        [[-CustomGetObjectName] <ScriptBlock>] 
        [[-NameExistsFunction] <ScriptBlock>] 
        [<CommonParameters>]


## Parameters
    -ServerInstance <String>
        The sql server instance to connect to.

        Required?                    true
        Position?                    1
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Databases <String[]>
        The database. If the value ALL_USER_DATABASES is passed in then, the renames will be applied to all user databases.

        Required?                    true
        Position?                    2
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Credentials <PSCredential>
        Specifies credentials to connect to the database with. If not supplied 
        then a trusted connection will be used.

        Required?                    false
        Position?                    3
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -IncludeSchemaInNames <SwitchParameter>
        If enabled then all names will include the schema as part of the name.
    
        The default naming conventions are as follows when this switch is 
        enabled:

        * Default Constraint = "DF_SchemaName_TableName_ColumnName"
        * Check Constraint = "CK_SchemaName_TableName_ColumnName"
        * Foreign Key = "FK_SchemaName_TableName_RemoteSchemaName_RemoteTableName"
        * Primary Key = "PK_SchemaName_TableName"
        * Unique Constraint = "UQ_SchemaName_TableName_ColumnName"
        * Unique Index = "UX_SchemaName_TableName_ColumnName"
        * Non-Clustered Index = "IX_SchemaName_TableName_ColumnName"     
    
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -Force <SwitchParameter>
        If enabled then all constraint names will be renamed even if they match 
        the expected naming conventions.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CustomGetObjectName <ScriptBlock>
        This script block can be passed in to override the naming convention 
        used.
        
        The method signature is as follows: 
            function GetObjectName($obj, [switch]$IncludeSchemaInNames)
        
        Note: Each of the details properties holds different values based upon 
        object type
        
        $obj is an objection with the following properties:
            schema_name: The schema name of the object
            table_name: The name of the view or table parent object
            object_name: The name of the constraint or index.
            details1: 
                C       : The column name used or null if the column could not 
                          be determined
                D       : The column name used or null if the column could not 
                          be determined
                FK      : The schema of the remote table name
                Index   : The first column used in the index key
                PK      : The first column used in the index key
            details2: 
                C       : The check constraint definition
                D       : NULL
                FK      : The table name of the remote table name
                Index   : A full list of the columns used in the index comma 
                          delimited
                PK      : A full list of the columns used in the index comma 
                          delimited
            details3: 
                C       : NULL
                D       : NULL
                FK      : NULL
                Index   : The detailed type of the index
                PK      : The detailed type of the index
            type: The type of object

        Required?                    false
        Position?                    4
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -CustomNameExists <ScriptBlock>
        This scriptblock can be passed in to override the base functionality 
        when the names produced already exist and come into conflict. By default 
        if the name already exists then a number will be suffixed to the name in 
        the pattern: 000. Starting with 001. A unique name for this object 
        should be returned. 
        
        EX: If a conflict occurs with IX_TableName_ColName then 
        IX_TableName_ColName_001 will be tried, then 002 and so on until a 
        unique name can be found.
        
        The method signature is as follows: 
            function CustomNameExists($newName, $renames)
        
        The parameter $renames will be a collection of names that have already 
        been assigned to the table. The $newName parameter will be the name that 
        was created.

        Required?                    false
        Position?                    5
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
## Examples

### Example
Rename all the constraints in all user databases.
    
```powershell
Invoke-DBRenameConstraints `
    -ServerInstance "ServerName" `
    -Databases "ALL_USER_DATABASES"
```

### Example
Rename all the constraints in the AdventureWorks2012 database
    
```powershell
Invoke-DBRenameConstraints `
    -ServerInstance "ServerName" `
    -Databases "AdventureWorks2012"
```

### Example
Rename all the constraints in the AdventureWorks2012 database using a custom naming function.

```powershell
$GetObjectName = {
    Param($obj, [switch]$IncludeSchemaInNames)

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
            $ret = "FK$($schemaNamePart)_$($obj.table_name)_$($remoteTable)"
        }        
        { $_ -ieq "PK" } { $ret = "PK$($schemaNamePart)_$($obj.table_name)" }
        { $_ -ieq "UQ" } { $ret = "UQ$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "UX" } { $ret = "UX$($schemaNamePart)_$($obj.table_name)$details" }
        { $_ -ieq "NC" } { $ret = "IX$($schemaNamePart)_$($obj.table_name)$details" }
        default { Write-Error "Unable to get constraint name for $($_)" }
    }

    return $ret
}

# IF you provide a custom name function, you might also want to add a override for the duplicate name exists function
$NameExistsFunction = {
    param ($newName, $renames)

    for ($i = 1; $i -lt 1000; $i++) {
        $suffix = "00$i"
        $suffix = $suffix.Substring($suffix.Length - 3)
        $tmpName = "$($newName)_$suffix"
        if (-not ($renames.Keys -icontains $tmpName)) {
            $newName = $tmpName
            break;
        }
    }
    return $newName
}

Invoke-DBRenameConstraints `
    -ServerInstance "ServerName" `
    -Databases "AdventureWorks2012" `
    -InformationAction Continue `
    -CustomGetObjectName $GetObjectName `
    -CustomNameExists $NameExistsFunction | Format-Table
```

<br/>
<br/>
  
[Back](/README.md)
