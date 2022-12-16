#Requires -Modules Invoke-SqlCmd2

function Invoke-DBRenameConstraints {
    <#
    .SYNOPSIS
        Will rename all indexes and constraints to match naming conventions.

    .DESCRIPTION
        Will rename all indexes and constraints to match naming conventions. Any constraint name that already matches the expected naming convention will be skipped.

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Databases
        The database.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER IncludeSchemaInNames
        If enabled then all names will include the schema as part of the name.

    .PARAMETER Force
        If enabled then all constraint names will be renamed even if they match the expected naming conventions.

    .PARAMETER CustomGetObjectName
        This script block can be passed in to override the naming convention used. The name of the object should be returned.

        The method signature is as follows: function GetObjectName($obj, [switch]$IncludeSchemaInNames)

        Note: Each of the details properties holds different values based upon object type

        $obj is an objection with the following properties:
            schema_name: The schema name of the object
            table_name: The name of the view or table parent object
            object_name: The name of the constraint or index.
            details1:
                C       : The column name used or null if the column could not be determined
                D       : The column name used or null if the column could not be determined
                FK      : The schema of the remote table name
                Index   : The first column used in the index key
                PK      : The first column used in the index key
            details2:
                C       : NULL
                D       : NULL
                FK      : The table name of the remote table name
                Index   : A full list of the columns used in the index comma delimited
                PK      : A full list of the columns used in the index comma delimited
            details3:
                C       : NULL
                D       : NULL
                FK      : NULL
                Index   : The detailed type of the index
                PK      : The detailed type of the index
            type: The type of object

    .PARAMETER NameExistsFunction
        This scriptblock can be passed in to override the base functionality when the names produced already exist and come into conflict. By default if the name already exists then a number will be suffixed to the name in the pattern: 0000. Starting with 0001. A unique name for this object should be returned.

        EX: If a conflict occurs with IX_TableName_ColName then IX_TableName_ColName_0001 will be tried, then 0002 and so on until a unique name can be found.

        The method signature is as follows: function GetObjectName($renames)

        The parameter $renames will be a collection of names that have already been assigned to the table.

    .EXAMPLE
        PS> .\Invoke-DBRenameConstraints -ServerInstance "servername" -Database "AdventureWorks2012"

    .EXAMPLE
        PS> .\Invoke-DBRenameConstraints -ServerInstance "servername" -Database "AdventureWorks2012" -UserName "user.name" -Password "ilovelamp"

    .EXAMPLE
        Using a custom naming function:

        $GetObjectName = {
            Param($obj, [switch]$IncludeSchemaInNames)

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

        Invoke-DBRenameConstraints -ServerInstance "server_name" -Databases "db1", "db2" -InformationAction Continue -CustomGetObjectName $GetObjectName | Format-Table

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [switch]$IncludeSchemaInNames,
        [switch]$Force,
        [scriptblock]$CustomGetObjectName,
        [scriptblock]$NameExistsFunction
    )

    begin {
        $sqlCon = InitSqlObjects -ServerInstance $ServerInstance -Database "master" -Credentials $Credentials
        $SqlCmdArguments = $sqlCon.SqlCmdArguments

        $connection = GetSQLConnection -ServerInstance $ServerInstance -Database "master" -Credentials $Credentials
        $connection.Open();
        $command = $connection.CreateCommand()
        $command.CommandType = "Text";

        $query = "
            SELECT [t].[schema_name],
                   [t].[table_name],
                   [t].[object_name],
                   [t].[details1],
                   [t].[details2],
                   [t].[details3],
                   RTRIM([t].[type]) AS [type]
            FROM (
	            SELECT
                        [schema_name]		= SCHEMA_NAME(fk.[schema_id]),
                        [table_name]		= OBJECT_NAME(fk.[parent_object_id]),
                        [object_name]		= fk.[name],
                        [details1]			= OBJECT_SCHEMA_NAME(fk.[referenced_object_id]),
                        [details2]			= OBJECT_NAME(fk.[referenced_object_id]),
                        [details3]			= NULL,
                        [o].[type]
                    FROM sys.[foreign_keys] fk
                    INNER JOIN sys.[objects] o ON fk.[object_id] = o.[object_id]
                    WHERE OBJECTPROPERTY(fk.[parent_object_id], 'IsMSShipped') = 0

                    UNION ALL

                    SELECT
                        [schema_name]		= SCHEMA_NAME(o.[schema_id]),
                        [table_name]		= OBJECT_NAME(i.[object_id]),
                        [object_name]		= i.[name],
                        [details1]			= COL_NAME(i.[object_id], ic.[column_id]),
                        [details2]			= fn.[names],
                        [details3]			= CASE
                                                    WHEN i.[type] = 1 THEN 'Clustered index'
                                                    WHEN i.[type] = 2 THEN 'Nonclustered unique index'
                                                    WHEN i.[type] = 3 THEN 'XML index'
                                                    WHEN i.[type] = 4 THEN 'Spatial index'
                                                    WHEN i.[type] = 5 THEN 'Clustered columnstore index'
                                                    WHEN i.[type] = 6 THEN 'Nonclustered columnstore index'
                                                    WHEN i.[type] = 7 THEN 'Nonclustered hash index'
                                                END,
                        [type]				=	CASE
                                                    WHEN i.[is_unique_constraint] = 1 THEN 'UQ'
                                                    WHEN i.[is_primary_key] = 1 THEN 'PK'
                                                    WHEN i.[is_unique_constraint] = 1 THEN 'UX'
                                                    ELSE 'NC'
                                                END
                    FROM  sys.[indexes] i
                    INNER JOIN sys.[objects] o ON i.[object_id] = o.[object_id]
                    INNER JOIN sys.[index_columns] AS [ic]
                        ON [ic].[object_id] = [i].[object_id]
                            AND [ic].[index_id] = [i].[index_id]
                            AND ic.[index_column_id] = 1
                    CROSS APPLY (
                        SELECT STUFF((
                            SELECT CONCAT(', ', COL_NAME(i.[object_id], ic2.[column_id]))
                            FROM sys.[index_columns] AS [ic2]
                                WHERE [ic2].[object_id] = [i].[object_id]
                                AND [ic2].[index_id] = [i].[index_id]
                            FOR XML PATH('')
                        ), 1, 2, '')  AS [names]
                    ) fn
                    WHERE i.type > 0
                        AND OBJECTPROPERTY(o.[object_id], 'IsMSShipped') = 0
                        AND OBJECTPROPERTYEX(o.[object_id], 'BaseType') <> 'TT' -- ignore table types as their constraints cannot be named


                    UNION ALL

                    SELECT
                        [schema_name]		= SCHEMA_NAME(o.[schema_id]),
                        [table_name]		= OBJECT_NAME(s.[id]),
                        [object_name]		= o.[name],
                        [details1]			= COL_NAME(s.[id], s.[colid]),
                        [details2]			= NULL,
                        [details3]			= NULL,
                        [o].[type]
                    FROM  sys.[sysconstraints] s
                    INNER JOIN sys.[objects] o ON s.[constid] = o.[object_id]
                    WHERE o.type NOT IN ('F', 'PK', 'UQ')
                        AND OBJECTPROPERTY(s.[id], 'IsMSShipped') = 0
                        AND OBJECTPROPERTYEX(s.[id], 'BaseType') <> 'TT' -- ignore table types as their constraints cannot be named
            ) t
            ORDER BY [t].[schema_name],
	            [t].[table_name],
	            [t].[object_name]"

        $sql = "EXEC sys.sp_rename @objname=N'{0}', @newname=N'{1}', @objtype=N'{2}';`r`n"
        $tempRenames = @{}
        $renames = @{}
        $output = [System.Collections.ArrayList]::new()
    }

    process {
        foreach ($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $results = Invoke-Sqlcmd @SqlCmdArguments -Query $query -OutputAs DataRows
            $grouped = $results | Group-Object -Property schema_name, table_name

            foreach ($item in $grouped) {
                $renames.Clear()
                $tempRenames.Clear()
                $objectName = $item.Name -replace ", ", "."

                foreach ($grp in $item.Group) {
                    if (-not $CustomGetObjectName) {
                        $newName = GetObjectName -obj $grp -IncludeSchemaInNames:$IncludeSchemaInNames.IsPresent
                    } else {
                        $newName = $CustomGetObjectName.Invoke($grp, $IncludeSchemaInNames.IsPresent) | Select-Object -Last 1
                    }

                    if (-not $NameExistsFunction) {
                        if ($renames.ContainsKey($newName)) {
                            for ($i = 1; $i -lt 1000; $i++) {
                                $suffix = "000$i"
                                $suffix = $suffix.Substring($suffix.Length - 4)
                                $tmpName = "$($newName)_$suffix"
                                if (-not $renames.ContainsKey($tmpName)) {
                                    $newName = $tmpName
                                    break;
                                }
                            }
                        }
                    } else {
                        $newName = $NameExistsFunction.Invoke($renames) | Select-Object -Last 1
                        if ($renames.ContainsKey($newName)) {
                            throw "The $newName name returned by the custom name exists function is not unique and already exists."
                        }
                    }
                    # unless force is present, do not rename this, as it already matches our desired name
                    if (-not $Force.IsPresent -and $newName -ieq $grp.object_name) {
                        # store this, so the numbers will work properly in the for loop above
                        $renames.Add($newName, "") | Out-Null
                        continue
                    }

                    $tempName = "tmp_$([Guid]::NewGuid().ToString("N"))"
                    # handle the crappy case where their old name had brackets in it. :|
                    $oldName = $grp.object_name -replace "\[", "\[\[" -replace "\]", "\]\]"

                    # we must first rename the constraints to some super generic name to avoid name collisions, then immediately rename it back
                    if ($grp.type.Trim() -ine "NC") {
                        $tempSql = $sql -f "[$($grp.schema_name)].[$oldName]", "$tempName", "OBJECT"
                        $tempRenames.Add($newName, $tempSql) | Out-Null

                        $tempSql = $sql -f "[$($grp.schema_name)].[$($tempName)]", $newName, "OBJECT"
                        $renames.Add($newName, $tempSql) | Out-Null
                    } else {
                        $tempSql = $sql -f "[$($grp.schema_name)].[$($grp.table_name)].[$oldName]", "$tempName", "INDEX"
                        $tempRenames.Add($newName, $tempSql) | Out-Null

                        $tempSql = $sql -f "[$($grp.schema_name)].[$($grp.table_name)].[$tempName]", "$newName", "INDEX"
                        $renames.Add($newName, $tempSql) | Out-Null
                    }

                    $output.Add([PSCustomObject] @{
                        Database = $Database
                        ObjectName = $objectName
                        Type = $grp.Type
                        OldConstraintName = $oldName
                        NewConstraintName = $newName
                    }) | Out-Null
                }
                if ($renames.Count -gt 0 -and "$($renames.Values)".Trim().Length -gt 0) {
                    $renameSql = "
/***********************************************************************************************************/
/*********************** Start renames for $Database $objectName ************************************/
/***********************************************************************************************************/
USE [$($Database)]
SET XACT_ABORT ON
/***********************************************************************************************************/
/***Rename the constraints for $Database $objectName to temporary names to avoid collisions**********/
/***********************************************************************************************************/
$($tempRenames.Values)
/***********************************************************************************************************/
/***Rename the constraints for $Database $objectName to their new permanent names********************/
/***********************************************************************************************************/
$($renames.Values)"

                    $ErrorActionPreference = "Stop"
                    try {
                        Write-Information $renameSql
                        $command.CommandText = $renameSql;
                        $command.ExecuteNonQuery() | Out-Null
                    } catch {
                        Write-InformationColored $_.Exception.Message -ForegroundColor Red
                    }
                    $ErrorActionPreference = "Continue"
                } else {
                    Write-InformationColored "No renames available for [$Database] object: $($objectName)" -ForegroundColor Yellow
                }
            }
        }
    }

    end {
        if ($command) { $command.Dispose() }
        if ($connection) { $connection.Dispose() }
        return $output | Sort-Object Database, ObjectName, NewConstraintName
    }
}

