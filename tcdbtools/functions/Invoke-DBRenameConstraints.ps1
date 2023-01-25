function Invoke-DBRenameConstraints {
    <#
    .SYNOPSIS
        Will rename all indexes and constraints to match naming conventions.

    .DESCRIPTION
        Will rename all indexes and constraints to match naming conventions. Any constraint name that already matches the expected naming convention will be skipped.

        The default naming conventions are as follows:

        * Default Constraint = "DF_TableName_ColumnName"
        * Check Constraint = "CK_TableName_ColumnName"
        * Foreign Key = "FK_TableName_RemoteTableName"
        * Primary Key = "PK_TableName"
        * Unique Constraint = "UQ_TableName_ColumnName"
        * Unique Index = "UX_TableName_ColumnName"
        * Non-Clustered Index = "IX_TableName_ColumnName"

    .PARAMETER ServerInstance
        The sql server instance to connect to.

    .PARAMETER Databases
        The databases operate on. If the value ALL_USER_DATABASES is passed in then, the renames will be applied to all user databases.

    .PARAMETER Credentials
        Specifies credentials to connect to the database with. If not supplied then a trusted connection will be used.

    .PARAMETER IncludeSchemaInNames
        If enabled then all names will include the schema as part of the name.

        The default naming conventions are as follows when this switch is enabled:

        * Default Constraint = "DF_SchemaName_TableName_ColumnName"
        * Check Constraint = "CK_SchemaName_TableName_ColumnName"
        * Foreign Key = "FK_SchemaName_TableName_RemoteSchemaName_RemoteTableName"
        * Primary Key = "PK_SchemaName_TableName"
        * Unique Constraint = "UQ_SchemaName_TableName_ColumnName"
        * Unique Index = "UX_SchemaName_TableName_ColumnName"
        * Non-Clustered Index = "IX_SchemaName_TableName_ColumnName"

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
                C       : The check constraint definition
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

    .PARAMETER CustomNameExists
        This scriptblock can be passed in to override the base functionality when the names produced already exist and come into conflict. By default if the name already exists then a number will be suffixed to the name in the pattern: 0000. Starting with 0001. A unique name for this object should be returned.

        EX: If a conflict occurs with IX_TableName_ColName then IX_TableName_ColName_0001 will be tried, then 0002 and so on until a unique name can be found.

        The method signature is as follows: function GetObjectName($newName, $renames)

        The parameter $renames will be a collection of names that have already been assigned to the table. The $newName parameter will be the name that was created.

    .PARAMETER Force
        If force is supplied, then all constraints will be renamed, regardless if they match the naming convention already or not.

    .EXAMPLE
        Rename all constraints in all user databases.

        Invoke-DBRenameConstraints `
            -ServerInstance "ServerName" `
            -Databases "ALL_USER_DATABASES"

    .EXAMPLE
        PS> Invoke-DBRenameConstraints -ServerInstance "servername" -Database "AdventureWorks2012"

    .EXAMPLE
        Using a custom naming function:

        $GetObjectName = {
            param ($obj, [switch]$IncludeSchemaInNames)

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

        # IF you provide a custom name function, you might also want to add a duplicate name exists function
        $NameExistsFunction = {
            param ($newName, $renames)

            for ($i = 1; $i -lt 1000; $i++) {
                $suffix = "00$i"
                $suffix = $suffix.Substring($suffix.Length - 3)
                $tmpName = "$($newName)_$suffix"
                if (-not ($renames -icontains $tmpName)) {
                    $newName = $tmpName
                    break;
                }
            }
            return $newName
        }

        Invoke-DBRenameConstraints -ServerInstance "server_name" `
            -Databases "db1", "db2" `
            -InformationAction Continue `
            -CustomGetObjectName $GetObjectName `
            -CustomNameExists $NameExistsFunction | Format-Table

    .LINK
        https://github.com/tcartwright/tcdbtools

    .NOTES
        Author: Tim Cartwright
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ServerInstance,
        [Parameter(Mandatory=$true)]
        [ValidateCount(1, 9999)]
        [string[]]$Databases,
        [pscredential]$Credentials,
        [switch]$IncludeSchemaInNames,
        [switch]$Force,
        [scriptblock]$CustomGetObjectName,
        [scriptblock]$CustomNameExists
    )

    begin {
        $SqlCmdArguments = New-DBSqlCmdArguments -ServerInstance $ServerInstance -Credentials $Credentials

        $connection = New-DBSQLConnection -ServerInstance $ServerInstance -Database "master" -Credentials $Credentials
        $connection.Open();
        $command = $connection.CreateCommand()
        $command.CommandType = "Text";

        $query = GetSQLFileContent -fileName "GetConstraints.sql"

        $sql = "EXEC sys.sp_rename @objname=N'{0}', @newname=N'{1}', @objtype=N'{2}';`r`n"
        $tempRenames = @{}
        $renames = @{}
        $output = [System.Collections.ArrayList]::new()

        $getName = $GetObjectNameFunction
        if ($CustomGetObjectName) {
            $getName = $CustomGetObjectName
        }
        $nameExists = $NameExistsFunction
        if ($CustomNameExists) {
            $nameExists = $CustomNameExists
        }
    }

    process {
        # if they passed in ALL_USER_DATABASES get all database names
        $Databases = Get-AllUserDatabases -Databases $Databases -SqlCmdArguments $SqlCmdArguments

        foreach ($Database in $Databases) {
            $SqlCmdArguments.Database = $Database
            $results = Invoke-Sqlcmd @SqlCmdArguments -Query $query -OutputAs DataRows
            $grouped = $results | Group-Object -Property schema_name, table_name

            foreach ($item in $grouped) {
                $renames.Clear()
                $tempRenames.Clear()
                $objectName = $item.Name -replace ", ", "."

                foreach ($grp in $item.Group) {
                    $newName = $getName.Invoke($grp, $IncludeSchemaInNames.IsPresent) | Select-Object -Last 1

                    if ($renames.Keys -icontains $newName) {
                        $newName = $nameExists.Invoke($newName, $renames) | Select-Object -Last 1
                        # even after trying to find a new custom name it still exists, then we have to bail... :|
                        if ($renames.Keys -icontains $newName) {
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
                    $oldName = (($grp.object_name -replace "\[", "\[\[") -replace "\]", "\]\]")

                    # we must first rename the constraints to some super generic name to avoid name collisions, then immediately rename it back
                    if (-not (@("NC", "UX") -icontains $grp.type.Trim())) {
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
                    Write-Information "Adding rename for database [$Database]: [$oldName] TO [$newName]"

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
                        Write-InformationColorized $_.Exception.Message -ForegroundColor Red
                    }
                    $ErrorActionPreference = "Continue"
                } else {
                    Write-InformationColorized "No renames available for [$Database] object: $($objectName)" -ForegroundColor Yellow
                }
            }
        }
    }

    end {
        if ($command) { $command.Dispose() }
        if ($connection) { $connection.Dispose() }
        if ($output.Count -eq 0) {
            Write-Warning "No renames found at all for any of the specified databases: `r`n`t$([string]::Join(",`r`n`t", $Databases))"
        }
        return $output | Sort-Object Database, ObjectName, NewConstraintName
    }
}